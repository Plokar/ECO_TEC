// Seeds quests, rewards and a few map pins. Without this the app has nothing to
// show on day one — `dailyQuest()` rotates through whatever is in `quests`.
//
//   npm install firebase-admin
//   # service account key: Firebase console -> Project settings -> Service accounts
//   GOOGLE_APPLICATION_CREDENTIALS=./serviceAccount.json node seed.mjs
//
// Safe to re-run: every write is keyed by a stable document id, so it updates in
// place instead of piling up duplicates.

import { cert, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { readFileSync } from 'node:fs';

const keyPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
if (!keyPath) {
  console.error(
    'Set GOOGLE_APPLICATION_CREDENTIALS to your service account JSON path.\n' +
      'Firebase console -> Project settings -> Service accounts -> Generate new private key',
  );
  process.exit(1);
}
initializeApp({ credential: cert(JSON.parse(readFileSync(keyPath, 'utf8'))) });
const db = getFirestore();

// Class names must match assets/models/ecoquest_labels.json exactly — the app
// filters detections by string, so a typo here silently makes a quest
// impossible to complete.
const CLASSES = [
  'plastic',
  'glass',
  'metal',
  'paper',
  'cigarette',
  'organic',
  'other_litter',
];

// Document ids are zero-padded because dailyQuest() orders by id and rotates by
// day number; padding keeps day 2 from sorting after day 10.
const DAILY = [
  {
    id: 'daily-01',
    title: 'Collect 10 pieces of plastic',
    description: 'Bottles, wrappers, bags — anything plastic counts.',
    targetClasses: ['plastic'],
    targetCount: 10,
    xpReward: 150,
    pointsReward: 25,
  },
  {
    id: 'daily-02',
    title: 'Five cans, one photo',
    description: 'Aluminium is the highest-value thing you can pull out of a park.',
    targetClasses: ['metal'],
    targetCount: 5,
    xpReward: 180,
    pointsReward: 30,
  },
  {
    id: 'daily-03',
    title: 'Clear 15 cigarette butts',
    description: 'One butt pollutes up to 40 litres of water. These add up fast.',
    targetClasses: ['cigarette'],
    targetCount: 15,
    xpReward: 200,
    pointsReward: 35,
  },
  {
    id: 'daily-04',
    title: 'Mixed bag: 12 items',
    description: 'Anything the detector recognises. Sort it properly afterwards.',
    targetClasses: [],
    targetCount: 12,
    xpReward: 160,
    pointsReward: 28,
  },
  {
    id: 'daily-05',
    title: 'Glass rescue — 4 pieces',
    description: 'Broken glass is the most dangerous litter in a playground.',
    targetClasses: ['glass'],
    targetCount: 4,
    xpReward: 190,
    pointsReward: 32,
  },
  {
    id: 'daily-06',
    title: 'Paper round: 10 items',
    description: 'Cartons, cups, magazines. Wet paper still counts.',
    targetClasses: ['paper'],
    targetCount: 10,
    xpReward: 140,
    pointsReward: 22,
  },
  {
    id: 'daily-07',
    title: 'Bottle hunt — 8 bottles',
    description: 'Plastic or glass, your call.',
    targetClasses: ['plastic', 'glass'],
    targetCount: 8,
    xpReward: 170,
    pointsReward: 30,
  },
];

const BONUS = [
  {
    id: 'bonus-tree',
    title: 'Plant 5 trees',
    description: 'Join a local planting event, then log it.',
    targetClasses: [],
    targetCount: 1,
    xpReward: 600,
    pointsReward: 500,
    verification: 'self_report',
    sponsorName: 'Treedom',
  },
  {
    id: 'bonus-cycle',
    title: 'Cycle instead of driving',
    description: 'A trip you would normally have driven. We take your word for it.',
    targetClasses: [],
    targetCount: 1,
    xpReward: 250,
    pointsReward: 40,
    verification: 'self_report',
  },
  {
    id: 'bonus-metal-30',
    title: 'Scrap sweep: 30 metal items',
    description: 'A weekend-sized challenge. Bring a bag.',
    targetClasses: ['metal'],
    targetCount: 30,
    xpReward: 900,
    pointsReward: 300,
    sponsorName: 'Ecosia',
  },
];

const REWARDS = [
  {
    id: 'coffee-free',
    title: 'Free filter coffee',
    partner: 'Bagels & Beans',
    costPoints: 250,
    stock: 500,
    terms: 'One per person per week. Participating stores in NL only.',
  },
  {
    id: 'tram-day',
    title: 'Day ticket, city transport',
    partner: 'GVB Amsterdam',
    costPoints: 900,
    stock: 120,
    terms: 'Valid 24 h from activation. Not transferable.',
  },
  {
    id: 'bottle-steel',
    title: 'Insulated steel bottle',
    partner: 'Dopper',
    costPoints: 2400,
    stock: 40,
    terms: 'Ships within the EU. Allow 10 working days.',
  },
  {
    id: 'tree-donation',
    title: 'Plant a tree in your name',
    partner: 'Trees for All',
    costPoints: 1500,
    stock: 9999,
    terms: 'You get a certificate with the planting location.',
  },
  {
    id: 'festival-pair',
    title: 'Two tickets, DGTL Festival',
    partner: 'DGTL',
    costPoints: 12000,
    stock: 6,
    terms: 'Subject to availability. 18+.',
  },
];

// Amsterdam city centre, roughly. Gives a new install something on the map.
const PINS = [
  { id: 'pin-vondel', kind: 'litterHotspot', lat: 52.3580, lng: 4.8686, title: 'Vondelpark south entrance' },
  { id: 'pin-centraal', kind: 'litterHotspot', lat: 52.3791, lng: 4.9003, title: 'Centraal Station bike racks' },
  { id: 'pin-recycle-jordaan', kind: 'recyclingPoint', lat: 52.3740, lng: 4.8830, title: 'Glass & paper containers' },
  { id: 'pin-recycle-oost', kind: 'recyclingPoint', lat: 52.3620, lng: 4.9270, title: 'Recycling point Oost' },
  { id: 'pin-cleanup-ij', kind: 'cleanupEvent', lat: 52.3850, lng: 4.9100, title: 'IJ riverside cleanup, Saturday 10:00' },
];

function validate() {
  const problems = [];
  for (const q of [...DAILY, ...BONUS]) {
    for (const c of q.targetClasses) {
      if (!CLASSES.includes(c)) {
        problems.push(`${q.id}: unknown class "${c}"`);
      }
    }
    if (q.targetCount < 1) problems.push(`${q.id}: targetCount must be >= 1`);
  }
  for (const p of PINS) {
    if (Math.abs(p.lat) > 90 || Math.abs(p.lng) > 180) {
      problems.push(`${p.id}: coordinates out of range`);
    }
  }
  if (problems.length) {
    console.error('Seed data is invalid:\n  ' + problems.join('\n  '));
    process.exit(1);
  }
}

async function main() {
  validate();
  const batch = db.batch();

  for (const q of DAILY) {
    const { id, ...rest } = q;
    batch.set(
      db.collection('quests').doc(id),
      { ...rest, isDaily: true, verification: rest.verification ?? 'ai_photo' },
      { merge: true },
    );
  }

  for (const q of BONUS) {
    const { id, ...rest } = q;
    batch.set(
      db.collection('quests').doc(id),
      { ...rest, isDaily: false, verification: rest.verification ?? 'ai_photo' },
      { merge: true },
    );
  }

  for (const r of REWARDS) {
    const { id, ...rest } = r;
    batch.set(db.collection('rewards').doc(id), rest, { merge: true });
  }

  for (const p of PINS) {
    const { id, ...rest } = p;
    batch.set(
      db.collection('mapPins').doc(id),
      { ...rest, resolved: false, uid: 'seed', createdAt: new Date() },
      { merge: true },
    );
  }

  await batch.commit();
  console.log(
    `Seeded ${DAILY.length} daily quests, ${BONUS.length} bonus quests, ` +
      `${REWARDS.length} rewards, ${PINS.length} map pins.`,
  );
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
