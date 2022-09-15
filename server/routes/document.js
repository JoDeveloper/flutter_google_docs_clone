const express = require('express');
const auth = require('../middelwares/auth.middleware');
const Document = require('../models/document');
const DocumentRouter = express.Router();


DocumentRouter.post('/docs/create',auth, async (req, res)=> { 
  try {
    const { createdAt } = req.body;
    
    let document = new Document({
      uid: req.user,
      title: 'Untitled Document',
      createdAt: createdAt,
    });

    document = await document.save();
    return res.json(document);

  } catch (error) {
    console.log(error);
    res.status(500).json({error: error.message});
  }
});

DocumentRouter.post('/docs/change-title',auth, async (req, res)=> { 
  try {
    const { id, title } = req.body;
    
    const document =  await Document.findByIdAndUpdate(id, { title });
    if(document)
      return res.status(202).json({success:'document was successfully changed to '+document.title});

  } catch (error) {
    console.log(error);
    res.status(500).json({error: error.message});
  }
});

DocumentRouter.get('/docs/me', auth, async (req, res) => { 
  try {
    const userId = req.user;
    let docs = await Document.find({ uid: userId });
    res.json({docs});
  } catch (error) {
    console.log(error);
    res.status(500).json({error: error.message});
  }
});

DocumentRouter.get('/docs/:id', auth, async (req, res) => { 
  try {

    const doc = await Document.findById(req.params.id);
    res.json({doc});
  } catch (error) {
    console.log(error);
    res.status(500).json({error: error.message});
  }
});


module.exports = DocumentRouter;
