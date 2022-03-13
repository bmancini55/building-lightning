import express from "express";

const app: express.Express = express();

app.listen(8000, () => {
    console.log("listening port 8000");
});
