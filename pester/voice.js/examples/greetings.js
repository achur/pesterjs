var fs = require('fs');
var voicejs = require('../voice.js');

var client = new voicejs.Client({
    email: 'email',
    password: 'password',
    tokens: require('./tokens.json')
});


// Display all greetings
client.greetings('get', function(error, response, data){
    if(error){
        return console.log(error);
    }
    
    console.log('\Greetings:');
    data.settings.greetings.forEach(function(greeting){
        console.log(greeting.id + ': ' + greeting.name);
    });
    
	// Download the audio for the default system greeting
    client.greetings('getAudio', {id: 0}, function(error, response, data){
        if(error){
            return console.log('Error downloading audio: ', error);
        }

        fs.writeFileSync('defaultGreeting.mp3', data);
        console.log('defaultGreeting.mp3 downloaded');
	});
});


// REMOVE THE FOLLOWNIG LINE TO MAKE CHANGES TO YOUR GV ACCOUNT AFTER YOU'VE REVIEWED THE CHANGES BELOW!
return;


// Create new greeting, call to record the greeting, cancel the call, and delete the greeting
client.greetings('new',{name: 'voice.js greeting', default: false}, function(error, response, data){
	if(error){
		console.log('Error creating greeting:', error);
	}
	
	var greetingId = data.greeting.id;
	console.log('Created new greeting with id:', greetingId);
	
	
	// Record the greeting
	client.greetings('record',{
		id: greetingId,
		number: 'email@gmail.com' // Call Google Talk to record the greeting. Note: This must be one of your forwarding phones.
	}, function(error, response, data){
		
		if(error){
			return console.log('Error initiating greeting record:', error);
		}
		
		console.log('Calling to record greeting');
		
		//cancel the call after 10 seconds and delete the greeting
		setTimeout(function(){
			
			console.log('Canceling the recording call...');
			client.greetings('cancelRecord', function(error, response, data){
				
				console.log(error ? error : 'Canceled recording');
				
				// Delete the greeting
				console.log('Deleting the greeting');
				client.greetings('delete', {id:greetingId}, function(error, response, data){
					console.log(error ? error : 'Deleted greeting');
				});
			})
		}, 10000)
	});
});