const express = require("express");
//const Axios = require("axios");
const dotenv = require("dotenv").config();
const cors = require("cors");
const { artiste } = require("./localDb");

const app = express();

app.use(cors());
app.use(express.urlencoded({ extended: false }));
app.use(express.json());

app.use((req, res, next) => {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Headers", "*");
  next();
});

app.get("/", (req, res) => {
  res.status(200).json({ message: "You are connected to the server" });
});

app.get(`/artiste/:artisteName/:songTitle`, async (req, res) => {
  const artisteName = req.params.artisteName;
  const songTitle = req.params.songTitle;
  const amount = await getRoyaltyAmount(artisteName, songTitle);
  res.status(200).json({ amount: amount });
});

app.listen(5000, () => {
  console.log("Server running on port 5000");
});

// functions toget data from db

const getRoyaltyAmount = async (artisteName, songTitle) => {
  for (let i = 0; i < artiste.length; i++) {
    const n_artiste = artiste[i];
    if (artiste[i].artisteName === artisteName) {
      const trackList = n_artiste.data.trackList;
      for (let i = 0; i < trackList.length; i++) {
        const track = trackList[i];
        if (track.title === songTitle) {
          console.log("ammount:", track.amount);
          return track.amount;
        }
      }
    }
  }
};
