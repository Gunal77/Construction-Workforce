const db = require('../config/db');
const { verifyToken } = require('../utils/jwt');

const authMiddleware = async (req, res, next) => {
  const authHeader = req.headers.authorization || '';
  const [scheme, token] = authHeader.split(' ');

  if (!token || scheme !== 'Bearer') {
    return res.status(401).json({ message: 'Authorization header missing or malformed' });
  }

  try {
    const decoded = verifyToken(token);
    const { rows } = await db.query('SELECT id, email FROM users WHERE id = $1', [decoded.id]);

    if (!rows.length) {
      return res.status(401).json({ message: 'User not found' });
    }

    req.user = rows[0];
    return next();
  } catch (error) {
    // Only log non-signature errors to reduce console spam
    // Invalid signature usually means token was signed with different secret (user needs to re-login)
    if (error.name !== 'JsonWebTokenError' || error.message !== 'invalid signature') {
      console.error('Auth middleware error', error.name, error.message);
    }
    return res.status(401).json({ 
      message: error.name === 'TokenExpiredError' 
        ? 'Token expired. Please log in again.' 
        : error.name === 'JsonWebTokenError' && error.message === 'invalid signature'
        ? 'Invalid token. Please log out and log in again.'
        : 'Invalid or expired token' 
    });
  }
};

module.exports = authMiddleware;

