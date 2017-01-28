metadata {
  definition (name: "NodeMCU Connected Door Sensor", namespace: "heythisisnate", author: "Nate Clark") {
    capability "Contact Sensor"
    capability "Sensor"
    command "open"
    command "close"
  }

  tiles {
    standardTile("contact", "device.contact", width: 2, height: 2) {
      state "open", label: '${name}', icon: "st.contact.contact.open", backgroundColor: "#ffa81e"
      state "closed", label: '${name}', icon: "st.contact.contact.closed", backgroundColor: "#79b821"
    }

    main "contact"
    details "contact"
  }
}

def open() {
  sendEvent(name: "contact", value: "open")
}

def close() {
  sendEvent(name: "contact", value: "closed")
}