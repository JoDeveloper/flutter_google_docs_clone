const express = require('express');
const User = require('../models/user');
const jwt = require('jsonwebtoken');
const auth = require('../middelwares/auth.middleware');

const authRouter = express.Router();


authRouter.post('/api/signup', async (req, res) => { 
  try {
    
    if (!req.body.profilePic || !req.body.email || !req.body.name) {
      return res.status(400).json({error:'email ,name m profilePic are required'});
    }
    const { name, email, profilePic } = req.body;
    // check if email is already exists
    let user = await User.findOne({email});
    if (!user) {
      user = await User({ name, email, profilePic });
      user =  await user.save();
    }
    const token = jwt.sign({id:user._id},'secret-jwt-key');
    return res.json({user,token});

  } catch (error) {
    console.log(error);
    res.status(500).json({error: error.message});
  }
});

authRouter.get('/api/getUserdata', auth, async (req, res) => { 
  const user = await User.findById(req.user);
  res.json({user:user,token:req.token});
});
 

module.exports = authRouter;
