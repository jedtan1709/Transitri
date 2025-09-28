// FTI GPS Service.js
// Background service for automatic GPS location polling

const GPSLocationService = {
    pollingInterval: null,
    isRunning: false,
    
    // Initialize the service
    init() {
        console.log('GPS Location Service initialized');
        this.startAutomaticPolling();
    },
    
    // Start automatic polling every 30 seconds
    startAutomaticPolling() {
        if (this.isRunning) {
            console.log('Service already running');
            return;
        }
        
        // Clear any existing interval
        if (this.pollingInterval) {
            clearInterval(this.pollingInterval);
        }
        
        // Start new interval - every 30 seconds
        this.pollingInterval = setInterval(() => {
            this.pollAllDevices();
        }, 30000); // 30 seconds
        
        this.isRunning = true;
        console.log('Automatic GPS polling started (30-second interval)');
        
        // Do initial poll immediately
        this.pollAllDevices();
    },
    
    // Stop automatic polling
    stopAutomaticPolling() {
        if (this.pollingInterval) {
            clearInterval(this.pollingInterval);
            this.pollingInterval = null;
        }
        this.isRunning = false;
        console.log('Automatic GPS polling stopped');
    },
    
    // Poll all registered devices for location updates
    pollAllDevices() {
        const devices = this.getDevices();
        const activeDevices = devices.filter(device => this.shouldTrackDevice(device));
        
        console.log(`Polling ${activeDevices.length} active devices for location...`);
        
        activeDevices.forEach(device => {
            this.requestDeviceLocation(device);
        });
        
        // Update last poll time
        this.updateLastPollTime();
    },
    
    // Request location from a specific device
    async requestDeviceLocation(device) {
        try {
            console.log(`Sending location request to ${device.driverName} (${device.simNumber})`);
            
            // Simulate sending SMS to device
            const success = await this.sendLocationRequestSMS(device);
            
            if (success) {
                // Simulate receiving location data after delay
                setTimeout(() => {
                    this.processLocationResponse(device, this.generateDeviceLocation(device));
                }, 2000 + Math.random() * 3000); // Random delay between 2-5 seconds
            } else {
                console.error(`Failed to send location request to ${device.driverName}`);
            }
        } catch (error) {
            console.error(`Error requesting location from ${device.driverName}:`, error);
        }
    },
    
    // Simulate sending SMS location request
    async sendLocationRequestSMS(device) {
        return new Promise((resolve) => {
            // Simulate SMS API call with 95% success rate
            setTimeout(() => {
                const success = Math.random() < 0.95;
                
                if (success) {
                    console.log(`📍 SMS location request sent to ${device.simNumber}`);
                    
                    // In real implementation, this would:
                    // 1. Send SMS to device SIM number
                    // 2. Device responds with coordinates
                    // 3. System processes the response
                }
                
                resolve(success);
            }, 500);
        });
    },
    
    // Process location response from device
    processLocationResponse(device, location) {
        const isInTerminal = this.isInTerminalArea(location.lat, location.lng);
        const now = new Date();
        
        // Update device data
        device.lastLocation = location;
        device.lastScanTime = now.toISOString();
        
        // Check if device just entered terminal area
        if (isInTerminal && !device.isInTerminal) {
            console.log(`🚗 ${device.driverName} entered terminal area`);
            device.trackingEnabled = true;
            device.trackingExpiry = new Date(now.getTime() + 60 * 60 * 1000).toISOString();
            
            // Show notification if UI is active
            this.showUINotification(`${device.driverName} entered terminal area`, 'success');
        }
        
        // Check if device left terminal area
        if (!isInTerminal && device.isInTerminal) {
            console.log(`🚗 ${device.driverName} left terminal area`);
        }
        
        device.isInTerminal = isInTerminal;
        
        // Save updated device data
        this.saveDevice(device);
        
        // Update any active tracking UI
        this.updateTrackingUI();
        
        console.log(`📍 ${device.driverName} location updated: ${location.lat.toFixed(6)}, ${location.lng.toFixed(6)}`);
    },
    
    // Generate mock location for simulation
    generateDeviceLocation(device) {
        const terminalCenter = this.getTerminalCenter();
        const variation = (Math.random() - 0.5) * 0.004; // ~400m variation
        
        // If device was in terminal, keep it nearby
        if (device.isInTerminal) {
            return {
                lat: terminalCenter.lat + (Math.random() - 0.5) * 0.002, // ~200m variation
                lng: terminalCenter.lng + (Math.random() - 0.5) * 0.002
            };
        }
        
        // Otherwise, random location within 2km
        return {
            lat: terminalCenter.lat + variation,
            lng: terminalCenter.lng + variation
        };
    },
    
    // Check if device should be tracked
    shouldTrackDevice(device) {
        if (!device.trackingEnabled) return false;
        
        const now = new Date();
        const expiry = new Date(device.trackingExpiry);
        
        // Check if tracking has expired
        if (now > expiry) {
            device.trackingEnabled = false;
            this.saveDevice(device);
            console.log(`⏰ Tracking expired for ${device.driverName}`);
            return false;
        }
        
        return true;
    },
    
    // Check if location is within terminal area
    isInTerminalArea(lat, lng) {
        const terminal = this.getTerminalCenter();
        const radius = this.getTerminalRadius();
        
        const R = 6371000; // Earth's radius in meters
        const dLat = this.deg2rad(lat - terminal.lat);
        const dLng = this.deg2rad(lng - terminal.lng);
        
        const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
                 Math.cos(this.deg2rad(terminal.lat)) * 
                 Math.cos(this.deg2rad(lat)) *
                 Math.sin(dLng/2) * Math.sin(dLng/2);
        
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
        const distance = R * c;
        
        return distance <= radius;
    },
    
    deg2rad(deg) {
        return deg * (Math.PI/180);
    },
    
    // Data management methods
    getDevices() {
        return JSON.parse(localStorage.getItem('gpsTrackingDevices') || '[]');
    },
    
    saveDevice(device) {
        const devices = this.getDevices();
        const index = devices.findIndex(d => d.id === device.id);
        
        if (index !== -1) {
            devices[index] = device;
            localStorage.setItem('gpsTrackingDevices', JSON.stringify(devices));
        }
    },
    
    getTerminalCenter() {
        const settings = JSON.parse(localStorage.getItem('systemSettings') || '{}');
        return settings.terminalCenter || { lat: 14.506908, lng: 121.041080 };
    },
    
    getTerminalRadius() {
        const settings = JSON.parse(localStorage.getItem('systemSettings') || '{}');
        return settings.terminalRadius || 500;
    },
    
    updateLastPollTime() {
        localStorage.setItem('lastGPSPoll', new Date().toISOString());
    },
    
    getLastPollTime() {
        return localStorage.getItem('lastGPSPoll');
    },
    
    // UI update methods
    updateTrackingUI() {
        // This would update any active tracking interface
        // In a real implementation, this would use a messaging system
        // to communicate with the main tracking page
        
        // For now, we'll dispatch a custom event
        const event = new CustomEvent('gpsDataUpdated', {
            detail: { timestamp: new Date().toISOString() }
        });
        window.dispatchEvent(event);
    },
    
    showUINotification(message, type) {
        // Dispatch notification event for UI to handle
        const event = new CustomEvent('showNotification', {
            detail: { message, type }
        });
        window.dispatchEvent(event);
    },
    
    // Service control methods
    getServiceStatus() {
        return {
            isRunning: this.isRunning,
            lastPoll: this.getLastPollTime(),
            deviceCount: this.getDevices().length,
            activeDevices: this.getDevices().filter(d => this.shouldTrackDevice(d)).length
        };
    }
};

// Initialize service when script loads
GPSLocationService.init();

// Export for use in other files
if (typeof module !== 'undefined' && module.exports) {
    module.exports = GPSLocationService;
}