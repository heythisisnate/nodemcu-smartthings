/**
 *  Cloud Service
 *
 *  Copyright © 2017 James VanBennekom
 *  
 *
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License. You may obtain a copy of the License at:
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed
 *  on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License
 *  for the specific language governing permissions and limitations under the License.
 */
 
definition(
    name: "Cloud Service",
    namespace: "jimvb",
    author: "JamesV",
    description: "Interfacing to and from SmartThings devices.",
    iconUrl: "https://s3.amazonaws.com/smartapp-icons/SafetyAndSecurity/Cat-SafetyAndSecurity.png",
    iconX2Url: "https://s3.amazonaws.com/smartapp-icons/SafetyAndSecurity/Cat-SafetyAndSecurity@2x.png",
    iconX3Url: "https://s3.amazonaws.com/smartapp-icons/SafetyAndSecurity/Cat-SafetyAndSecurity@2x.png",
  	oauth: true)


preferences {
    page name:"mainPage"
    page name:"showIDs"
    page name:"pageReset"
}

//Show main page
def mainPage() {
    dynamicPage(name: "mainPage", title:"", install: true, uninstall: false) {
		section("External control") {
        	input "switches", "capability.switch", title: "Choose Switches", multiple: true, required: false, submitOnChange:true
            input "contactSensors", "capability.contactSensor", title: "Contact sensors", multiple:true, required:false, submitOnChange:true
    		input "motionSensors", "capability.motionSensor", title: "Motion sensors", multiple:true, required:false, submitOnChange:true
    		input "smokeDetectors", "capability.smokeDetector", title: "Smoke detectors", multiple:true, required:false, submitOnChange:true
            href "showIDs", title: "Show IDs", description: "Tap to show Access Token and App ID"
        }
        section([title:"Options", mobileOnly:true]) {
			href "pageSecurity", title: "Security Options", description: "Tap to show security options"
        }
	}
}
//----------------------------- Start of show IDs
def showIDs(){
	dynamicPage(name: "showIDs", title:"ID's") {
        if (!state.accessToken) {
			OAuthToken()
		}
        if (state.accessToken != null) {
          		section ("App ID") {
					paragraph "", title: "${app.id}"
				}
        			section ("Access Token") {
					paragraph "", title: "${state.accessToken}"
				}	    
		}
        else {
        	section ("Error in creation of URLs"){
            	paragraph "Could not create URLs. Access Token not defined. OAuth may not be enabled. Go to the SmartApp IDE settings to enable OAuth."
            }
        }
	}
}
//----------------------------- End of show IDs
//----------------------------- Start of pageSecurity

page(name: "pageSecurity", title: "Security Options"){
	section{
    	href "pageReset", title: "Reset Access Token", description: "Tap to revoke access token. All current URLs in use will need to be re-generated"
	}
}
//----------------------------- END of pageSecurity
//----------------------------- Start of pageReset
def pageReset(){
	dynamicPage(name: "pageReset", title: "Access Token Reset"){
        section{
			state.accessToken = null
            OAuthToken()
            def msg = state.accessToken != null ? "New access token:\n${state.accessToken}\n\nClick 'Done' above to return to the previous menu." : "Could not reset Access Token. OAuth may not be enabled. Go to the SmartApp IDE settings to enable OAuth."
	    	paragraph "${msg}"
		}
	}
}
//----------------------------- End of pageSecurity
def installed() {
	log.debug "Installed with settings: ${settings}"
	initialize()
}

def updated() {
	log.debug "Updated with settings: ${settings}"
	initialize()
}

def initialize() {
	if (!state.accessToken) {
		log.error "Access token not defined. Ensure OAuth is enabled in the SmartThings IDE and generate the Access Token in the help or URL pages within the app."
	}
}
//----------------------------- Get Info from GET and control devices
mappings {
      path("/event") {action: [GET: "writeData"]}
}

def writeData() {
    log.debug "Command received with params $params"
	def command = params.c  	//The action you want to take i.e. on/off 
	def label = params.l		//The name given to the device by you
	def state = params.s
    def type = params.t
    def device = ""
	def allSensors = contactSensors + motionSensors + smokeDetectors
 	if (type == 'sensor') {
    device = allSensors.find{it.label == params.l}
    }
    if (type == 'switch') {
    device = switches?.find{it.label == label}
    }
	device."$command"()
    }
//----------------------------- END 


def OAuthToken(){
	try {
		createAccessToken()
		log.debug "Creating new Access Token"
	} catch (e) {
		log.error "Could not create URLs. Access Token not defined. OAuth may not be enabled. Go to the SmartApp IDE settings to enable OAuth."
	}
}