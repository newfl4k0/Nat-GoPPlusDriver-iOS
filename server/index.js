/**
 * Demo Server with Node.js
 */
const _              = require("underscore");
const express        = require('express');
const bodyparser     = require('body-parser');
const methodoverride = require('method-override');
const utils          = require('./utils');

const app = express();

app.use(bodyparser.urlencoded({ extended: false }));
app.use(bodyparser.json());
app.use(methodoverride());

app.get('/', function(req, res) {
	res.status(200).jsonp({ message: 'Hello World' });
});


app.post('/login', function(req, res) {
	var data = req.body;

	console.log(JSON.stringify(data));

	var status = 400;
	var response = {
		status: false,
		message: 'Verifica tus usuario y contraseña'
	};

	if (!utils.isEmptyValue(data.user) && !utils.isEmptyValue(data.password)) {
		status = 200;
		response.status = true;
		response.message = 'Bienvenido';
	}

	res.status(status).jsonp(response);
});

app.listen(9997, function() {
	console.log('Fa Server listening at 9997 time:' + new Date());
});
