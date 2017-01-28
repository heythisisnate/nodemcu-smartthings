metadata {
	definition (name: "NodeMCU Connected Motion Sensor", namespace: "heythisisnate", author: "Nate Clark") {
		capability "Motion Sensor"
		capability "Sensor"
    command "open"
    command "close"
	}

	tiles {
    standardTile("motion", "device.motion", width: 2, height: 2) {
    	state "active", label: '${name}', icon: "st.motion.motion.active"
    	state "inactive", label: '${name}', icon: "st.motion.motion.inactive"
		}

		main "motion"
		details "motion"
	}
}

def open() {
	sendEvent(name: "motion", value: "active")
}

def close() {
  sendEvent(name: "motion", value: "inactive")
}