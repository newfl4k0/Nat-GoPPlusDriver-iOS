const _ = require("underscore");

var isEmptyValue = function(data) {
	return _.isUndefined(data) || _.isEmpty(data);
};

exports.isEmptyValue = isEmptyValue;