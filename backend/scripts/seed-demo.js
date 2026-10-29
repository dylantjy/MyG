// Creates (or resets) a demo account with three weeks of push/pull/legs workouts.
// Run with the server stopped: npm run seed
// The server also calls seedDemo() on startup with the local database, creating the account if it's missing.
require('dotenv').config();
const bcrypt = require('bcryptjs');
const User = require('../models/User');
const Workout = require('../models/Workout');
const ChatHistory = require('../models/ChatHistory');

const DEMO_EMAIL = 'demo@myg.app';
const DEMO_PASSWORD = 'myg12345';

// [name, sets of [reps, kg]] for the first week; weights go up each week to show progressive overload
const PLAN = {
    Push: [
        ['incline smith press', [[10, 60], [8, 65], [8, 65]]],
        ['cable lateral raise', [[12, 10], [12, 10]]],
        ['machine chest press', [[10, 70], [9, 70]]],
        ['tricep pushdown', [[12, 30], [10, 32.5]]]
    ],
    Pull: [
        ['neutral grip pull down', [[10, 60], [9, 60], [8, 60]]],
        ['chest supported row', [[10, 50], [10, 50]]],
        ['rear delt fly', [[12, 35], [12, 35]]],
        ['preacher curl', [[10, 25], [9, 25]]]
    ],
    Legs: [
        ['hack squat', [[10, 100], [8, 110], [8, 110]]],
        ['leg extension', [[12, 60], [12, 60]]],
        ['seated hamstring curl', [[10, 50], [10, 50]]]
    ]
};

function buildExercise([name, sets], week) {
    const reps = sets.map(([r]) => r);
    const weights = sets.map(([, kg]) => kg + week * 2.5);
    const exerciseVolume = reps.reduce((sum, r, i) => sum + r * weights[i], 0);
    return { name, sets: sets.length, reps, weights, exerciseVolume };
}

// With reset: false, leaves an existing demo account untouched
async function seedDemo({ reset }) {
    let user = await User.findOne({ email: DEMO_EMAIL });
    if (user && !reset) {
        return false;
    }
    if (!user) {
        user = await User.create({
            email: DEMO_EMAIL,
            username: 'demo',
            password: await bcrypt.hash(DEMO_PASSWORD, 10)
        });
    }
    await Workout.deleteMany({ userId: user._id });
    await ChatHistory.deleteMany({ userId: user._id });

    const days = ['Push', 'Pull', 'Legs'];
    const workouts = [];
    for (let week = 0; week < 3; week++) {
        days.forEach((day, i) => {
            const date = new Date();
            date.setHours(9, 0, 0, 0);
            date.setDate(date.getDate() - (20 - week * 7 - i * 2));
            const exercises = PLAN[day].map(e => buildExercise(e, week));
            const workoutVolume = exercises.reduce((sum, e) => sum + e.exerciseVolume, 0);
            workouts.push({ name: day, userId: user._id, date, exercises, workoutVolume });
        });
    }
    await Workout.insertMany(workouts);
    console.log(`🌱 Seeded ${workouts.length} workouts for ${DEMO_EMAIL} / ${DEMO_PASSWORD}`);
    return true;
}

module.exports = { seedDemo, DEMO_EMAIL, DEMO_PASSWORD };

if (require.main === module) {
    const { connectDatabase, disconnectDatabase } = require('../db');
    connectDatabase()
        .then(where => {
            console.log(`Connected to ${where}`);
            return seedDemo({ reset: true });
        })
        .then(() => disconnectDatabase())
        .then(() => process.exit(0))
        .catch(err => {
            console.error('Seeding failed:', err.message);
            if (/lock|already in use|Address/i.test(err.message)) {
                console.error('Is the server still running? Stop it (Ctrl+C) and run npm run seed again.');
            }
            process.exit(1);
        });
}
