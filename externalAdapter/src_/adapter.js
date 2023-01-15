const process = require("process");
const express = require("express");
const cors = require("cors");
//const bodyParser = require("body-parser");
const axios = require("axios");

const port = process.env.PORT || 8080;
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
  res.send("external adapter is running");
});

app.post("/artiste", async (req, res) => {
  const eaInputData = req.body;
  console.log("request Recievesd", eaInputData);
  // build apiRequest
  const url = `http://localhost:5000/artiste/${eaInputData.data.artisteName}/${eaInputData.data.songTitle}`;

  //build response
  let eaOutput = {
    data: {},
    jobRunID: eaInputData.id,
    statusCode: 200,
  };

  try {
    const apiRespons = await axios.get(url);
    eaOutput.data = { result: apiRespons.data };
    eaOutput.statusCode = apiRespons.status;

    console.log("response sent", eaOutput);
    res.json(eaOutput);
  } catch (error) {
    console.log("api response error", error);
    eaOutput.error = error.message;
    eaOutput.statusCode = error.response.status;
    res.json(eaOutput);
  }
});

app.listen(port, () => {
  console.log(`Listening on port ${port}`);
});
