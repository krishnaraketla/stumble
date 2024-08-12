const express = require('express');
const bodyParser = require('body-parser');
const db = require('./models');
const globalRoutes = require("./routes/global");
const app = express();
const port = 3000;

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Use global routes
app.use('/global', globalRoutes);

// Home route
app.get('/', (req, res) => {
  res.send('Hello World!');
});

// Start server after syncing with DB
db.sequelize.sync().then(() => {
  app.listen(port, () => {
    console.log(`Server is running on http://localhost:${port}`);
  });
});