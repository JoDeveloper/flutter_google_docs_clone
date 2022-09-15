const jwt = require('jsonwebtoken');

const auth = async (req, res,next) => { 
  try {
    const token = req.header('x-auth-token');
    if (!token) return res.status(401).json({ error: 'Invalid Authorization, access denied' });

    const verified = jwt.verify(token, 'secret-jwt-key');
    if (!verified) return res.status(401).json({ error: 'Authorization denied' });

    req.user = verified.id;
    req.token = token;
    next();
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
}
module.exports  =auth;
