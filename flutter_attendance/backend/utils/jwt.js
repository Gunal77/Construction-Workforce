const jwt = require('jsonwebtoken');
const env = require('../config/env');

const DEFAULT_EXPIRY = '7d';

// Validate JWT_SECRET is set
if (!env.jwtSecret || env.jwtSecret.trim().length === 0) {
  throw new Error('JWT_SECRET is not set or is empty. Please check your .env file.');
}

const signToken = (payload, options = {}) =>
  jwt.sign(payload, env.jwtSecret, { expiresIn: DEFAULT_EXPIRY, ...options });

const verifyToken = (token) => {
  if (!env.jwtSecret || env.jwtSecret.trim().length === 0) {
    throw new Error('JWT_SECRET is not configured');
  }
  return jwt.verify(token, env.jwtSecret);
};

module.exports = {
  signToken,
  verifyToken,
};

