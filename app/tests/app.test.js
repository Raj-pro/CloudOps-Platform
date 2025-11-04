const request = require('supertest');
const app = require('../src/server');

describe('Application Tests', () => {
  afterAll((done) => {
    // Close server after tests
    done();
  });

  describe('GET /', () => {
    it('should return welcome message', async () => {
      const response = await request(app).get('/');
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('message');
      expect(response.body.message).toBe('Welcome to CloudOps Platform');
    });
  });

  describe('GET /health', () => {
    it('should return healthy status', async () => {
      const response = await request(app).get('/health');
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('status', 'healthy');
      expect(response.body).toHaveProperty('uptime');
    });
  });

  describe('GET /api/status', () => {
    it('should return application status', async () => {
      const response = await request(app).get('/api/status');
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('application');
      expect(response.body).toHaveProperty('status', 'running');
      expect(response.body).toHaveProperty('version');
    });
  });

  describe('GET /nonexistent', () => {
    it('should return 404 for non-existent routes', async () => {
      const response = await request(app).get('/nonexistent');
      expect(response.status).toBe(404);
      expect(response.body).toHaveProperty('message', 'Route not found');
    });
  });
});
