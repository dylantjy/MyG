const request = require('supertest');
const app = require('../index');

const mockCreate = jest.fn();
jest.mock('openai', () => ({
  OpenAI: jest.fn().mockImplementation(() => ({
    chat: { completions: { create: mockCreate } }
  }))
}));

describe('Photo macro scanner', () => {
  beforeEach(() => mockCreate.mockReset());

  it('sends the photo and description to the model and returns its macros', async () => {
    mockCreate.mockResolvedValue({
      choices: [{ message: { content: JSON.stringify({
        dish: 'Chicken rice', calories: 600, protein: 30, carbs: 75, fat: 20
      }) } }]
    });

    const res = await request(app)
      .post('/smartscan/photo-macros')
      .field('description', 'chicken rice')
      .attach('image', Buffer.from('fake image bytes'), { filename: 'meal.jpg', contentType: 'image/jpeg' });

    expect(res.statusCode).toBe(200);
    expect(res.body.dish).toBe('Chicken rice');
    expect(res.body.calories).toBe(600);

    const args = mockCreate.mock.calls[0][0];
    expect(args.response_format).toEqual({ type: 'json_object' });
    const content = args.messages[1].content;
    expect(content[0].text).toContain('chicken rice');
    expect(content[1].image_url.url).toMatch(/^data:image\/jpeg;base64,/);
  });

  it('passes through the not-edible response', async () => {
    mockCreate.mockResolvedValue({
      choices: [{ message: { content: JSON.stringify({ error: 'Not an edible food' }) } }]
    });

    const res = await request(app)
      .post('/smartscan/photo-macros')
      .attach('image', Buffer.from('leaf'), { filename: 'leaf.png', contentType: 'image/png' });

    expect(res.statusCode).toBe(200);
    expect(res.body.error).toBe('Not an edible food');
  });

  it('rejects a request without an image', async () => {
    const res = await request(app).post('/smartscan/photo-macros');
    expect(res.statusCode).toBe(400);
  });
});
