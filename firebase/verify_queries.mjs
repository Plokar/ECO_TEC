// Runs the exact queries DataService issues, to prove the deployed indexes cover
// them. Index requirements are enforced server-side, so the Admin SDK bypassing
// security rules doesn't weaken this check.
import { cert, initializeApp } from 'firebase-admin/app';
import { getFirestore, FieldPath } from 'firebase-admin/firestore';
import { readFileSync } from 'node:fs';

initializeApp({
  credential: cert(JSON.parse(readFileSync('./serviceAccount.json', 'utf8'))),
});
const db = getFirestore();

const checks = [
  [
    'dailyQuest()  quests where isDaily==true orderBy __name__',
    () => db.collection('quests').where('isDaily', '==', true).orderBy(FieldPath.documentId()).get(),
  ],
  [
    'bonusQuests()  quests where isDaily==false',
    () => db.collection('quests').where('isDaily', '==', false).get(),
  ],
  [
    'leaderboard(city)  users where city== orderBy xp desc',
    () => db.collection('users').where('city', '==', 'Plzeň').orderBy('xp', 'desc').limit(50).get(),
  ],
  [
    'leaderboard(country)',
    () => db.collection('users').where('country', '==', 'CZ').orderBy('xp', 'desc').limit(50).get(),
  ],
  [
    'leaderboard(school)',
    () => db.collection('users').where('school', '==', 'SPŠE Plzeň').orderBy('xp', 'desc').limit(50).get(),
  ],
  [
    'leaderboard(global)  users orderBy xp desc',
    () => db.collection('users').orderBy('xp', 'desc').limit(50).get(),
  ],
  [
    'leagueTable(city)  leagues where kind== orderBy points desc',
    () => db.collection('leagues').where('kind', '==', 'city').orderBy('points', 'desc').limit(25).get(),
  ],
  [
    'recentSubmissions()  submissions where uid== orderBy createdAt desc',
    () => db.collection('submissions').where('uid', '==', 'nobody').orderBy('createdAt', 'desc').limit(20).get(),
  ],
  [
    'rewards()  rewards orderBy costPoints',
    () => db.collection('rewards').orderBy('costPoints').get(),
  ],
  [
    'pinsNear()  mapPins lat range',
    () => db.collection('mapPins').where('lat', '>', 52.2).where('lat', '<', 52.5).limit(300).get(),
  ],
  [
    'searchPlayers()  users orderBy displayNameLower range',
    () => db.collection('users').orderBy('displayNameLower').startAt('se').endAt('se').limit(20).get(),
  ],
];

let failed = 0;
for (const [label, run] of checks) {
  try {
    const snap = await run();
    console.log(`  OK    ${label}  -> ${snap.size} docs`);
  } catch (e) {
    failed++;
    console.log(`  FAIL  ${label}`);
    console.log(`        ${e.code ?? ''} ${e.message.split('\n')[0]}`);
  }
}

// Confirm the daily rotation actually resolves to a quest.
const snap = await db.collection('quests').where('isDaily', '==', true).orderBy(FieldPath.documentId()).get();
const day = new Date(Date.UTC(2026, 7, 18));
const n = Math.floor((day - Date.UTC(2026, 0, 1)) / 86400000);
console.log(`\ntoday's quest (day ${n} of ${snap.size}): ${snap.docs[Math.abs(n) % snap.size].data().title}`);

console.log(failed ? `\n${failed} query/queries FAILED` : '\nall queries served by deployed indexes');
process.exit(failed ? 1 : 0);
