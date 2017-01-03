/**
 * Chat Library
 */

exports.getCurrentChat = function(carId, isClientChat) {
	if (isClientChat) {
		return [{
			id: 1004,
			isFromSender: false,
			message: 'Ask for Mrs Iceland apartment 101',
			date: '03 Ene 2017 12:05'
		},
		 {
			id: 1005,
			isFromSender: true,
			message: 'I\'m already here',
			date: '03 Ene 2017 12:06'
		}];
	} else {
		return [{
			id: 1001,
			isFromSender: true,
			message: 'Hello There',
			date: '03 Ene 2017 10:00'
		}, {
			id: 1002,
			isFromSender: true,
			message: '??',
			date: '03 Ene 2017 10:01'
		},
		 {
			id: 1003,
			isFromSender: false,
			message: 'Wait a moment',
			date: '03 Ene 2017 10:04'
		}];
	}
};