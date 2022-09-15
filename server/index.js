const express = require('express');
const mongoose = require('mongoose');
const authRouter = require('./routes/auth');
const cors = require("cors");
const http = require('http');

const DocumentRouter = require('./routes/document');

const PORT = process.env.PORT | 3001;
const DB = 'mongodb+srv://root:root1234@cluster0.mroel5t.mongodb.net/?retryWrites=true&w=majority';

const app = express();
// socket.io 
let server = http.createServer(app);
let io = require('socket.io')(server);

app.use(cors());
app.use(express.json());
app.use(authRouter);
app.use(DocumentRouter);

// DB
mongoose.connect(DB).then(() => {
  console.log('Connected to MongoDB');
}).catch((error) => {
  console.log(error);
});

// Io
io.on("connection", (socket) => {
  console.log('Connected to Io with socket Id:'+ socket.id);
  socket.on("join", (documentId) => {
    socket.join(documentId);
    console.log("Connection established to room" + documentId);
  });

  socket.on("typing", (data) => {
    socket.broadcast.to(data.room).emit("changes", data);
  });

  socket.on("save", (data) => {
    saveData(data);
  });
});

const saveData = async (data) => {
  let document = await Document.findById(data.room);
  document.content = data.delta;
  document = await document.save();
};

server.listen(PORT, "0.0.0.0", () => { 
  console.log("Express server listening on port " + PORT);
});
