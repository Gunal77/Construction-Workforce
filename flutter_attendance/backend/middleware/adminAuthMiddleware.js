const { verifyToken } = require('../utils/jwt');

const adminAuthMiddleware = (req, res, next) => {
  const authHeader = req.headers.authorization || '';
  const [scheme, token] = authHeader.split(' ');

  if (!token || scheme !== 'Bearer') {
    return res.status(401).json({ message: 'Authorization header missing or malformed' });
  }

  try {
    const decoded = verifyToken(token);

    if (decoded.role !== 'admin') {
      return res.status(403).json({ message: 'Admin privileges required' });
    }

    req.admin = {
      id: decoded.id,
      email: decoded.email,
      role: decoded.role,
    };
    return next();
  } catch (error) {
    // Only log non-signature errors to reduce console spam
    // Invalid signature usually means token was signed with different secret (user needs to re-login)
    if (error.name !== 'JsonWebTokenError' || error.message !== 'invalid signature') {
      console.error('Admin auth error', error.name, error.message);
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

module.exports = adminAuthMiddleware;


