const request = require('supertest');
const app = require('../index');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
const Workout = require('../models/Workout');

// Mock the LLM so the test doesn't depend on a running model or API key
const mockCreate = jest.fn().mockResolvedValue({
  choices: [{ message: { content: '- Add a rear delt exercise to balance your pressing.' } }]
});
jest.mock('openai', () => ({
  OpenAI: jest.fn().mockImplementation(() => ({
    chat: { completions: { create: mockCreate } }
  }))
}));

let workoutId;
let mongoServer;

beforeAll(async () => {
  mongoServer = await MongoMemoryServer.create();
  const uri = mongoServer.getUri();
  await mongoose.connect(uri); // no need for useNewUrlParser or useUnifiedTopology
});

afterAll(async () => {
  await mongoose.connection.dropDatabase();
  await mongoose.connection.close();
  await mongoServer.stop();
});

describe('Workout Routes', () => {
  it('should start a workout', async () => {
    const res = await request(app).post('/workout/start').send({
      name: 'Test Workout',
      userId: new mongoose.Types.ObjectId().toString(), // ✅ generate valid ID
      date: '2024-07-20'
    });
    expect(res.statusCode).toBe(201);
    workoutId = res.body.workoutId;
  });

  it('should add an exercise', async () => {
    const res = await request(app).patch(`/workout/${workoutId}/add-exercise`).send({
      name: 'Bench Press',
      sets: 3,
      reps: [10, 10, 8],
      weights: [50, 55, 60]
    });
    expect(res.statusCode).toBe(200);
  });

  it('should log workout and return AI suggestions', async () => {
    const res = await request(app).patch(`/workout/${workoutId}/log`);
    expect(res.statusCode).toBe(201);
    expect(res.body.suggestions).toContain('rear delt');
    expect(mockCreate.mock.calls[0][0].messages[1].content).toContain('bench press');
  });
});