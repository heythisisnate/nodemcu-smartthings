definition(
  name: "Cloud Sensor",
  namespace: "heythisisnate",
  author: "Nate Clark",
  description: "A generic webhook handler for internet connected contact or motion sensors",
  category: "Safety & Security",
  iconUrl: "https://s3.amazonaws.com/smartapp-icons/SafetyAndSecurity/Cat-SafetyAndSecurity.png",
  iconX2Url: "https://s3.amazonaws.com/smartapp-icons/SafetyAndSecurity/Cat-SafetyAndSecurity@2x.png"
)

preferences {
	section("Select devices to monitor") {
  	input "contactSensors", "capability.contactSensor", multiple:true
    input "motionSensors", "capability.motionSensor", multiple:true
	}
}

mappings {
  path("/event") {
    action: [
      POST: "handle_event"
    ]
  }
}

def handle_event() {
  def event = request.JSON
  def sensor_id = event.sensor_id 
  def allSensors = contactSensors + motionSensors
  def device = allSensors.find { 
    sensor_id == it.id
  }
  
  if(device == null)
    httpError(501, "Unknown device " + sensor_id)
    
  state.last_seen = now()
  
  if(event.state == 0){
    device.close();
  } 
  else if(event.state == 1){
    device.open();
  }
  else
    httpError(500, "Unknown device state " + event.state)
    

  log.trace "Updated " + device + " to " + event.state
  
  return [ "success": true ]
}