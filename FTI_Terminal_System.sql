-- Complete MySQL Database for FTI ARCA SOUTH Tricycle Terminal Management System

-- Create database
CREATE DATABASE IF NOT EXISTS fti_terminal_db;
USE fti_terminal_db;

-- Table: administrators
CREATE TABLE administrators (
    admin_id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100),
    phone_number VARCHAR(20),
    role ENUM('super_admin', 'admin', 'operator') DEFAULT 'admin',
    is_active BOOLEAN DEFAULT TRUE,
    last_login DATETIME,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_admin_username (username),
    INDEX idx_admin_role (role),
    INDEX idx_admin_active (is_active)
);

-- Table: terminals
CREATE TABLE terminals (
    terminal_id INT PRIMARY KEY AUTO_INCREMENT,
    terminal_code VARCHAR(20) UNIQUE NOT NULL,
    terminal_name VARCHAR(100) NOT NULL,
    address TEXT,
    contact_number VARCHAR(20),
    manager_name VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_terminal_code (terminal_code),
    INDEX idx_terminal_active (is_active)
);

-- Table: terminal_geofence
CREATE TABLE terminal_geofence (
    geofence_id INT PRIMARY KEY AUTO_INCREMENT,
    terminal_id INT NOT NULL,
    name VARCHAR(100) DEFAULT 'FTI ARCA SOUTH Terminal',
    center_latitude DECIMAL(10, 8) NOT NULL, -- 14.506908
    center_longitude DECIMAL(11, 8) NOT NULL, -- 121.041080
    radius_meters INT DEFAULT 500,
    is_active BOOLEAN DEFAULT TRUE,
    created_by INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (terminal_id) REFERENCES terminals(terminal_id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES administrators(admin_id),
    INDEX idx_geofence_terminal (terminal_id),
    INDEX idx_geofence_active (is_active)
);

-- Table: drivers
CREATE TABLE drivers (
    driver_id INT PRIMARY KEY AUTO_INCREMENT,
    driver_code VARCHAR(20) UNIQUE NOT NULL, -- Format: DRV-001
    full_name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    address TEXT,
    license_number VARCHAR(50),
    license_expiry DATE,
    photo_url VARCHAR(500),
    status ENUM('active', 'inactive', 'suspended') DEFAULT 'active',
    terminal_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (terminal_id) REFERENCES terminals(terminal_id) ON DELETE CASCADE,
    INDEX idx_driver_status (status),
    INDEX idx_driver_phone (phone_number),
    INDEX idx_driver_terminal (terminal_id)
);

-- Table: vehicles
CREATE TABLE vehicles (
    vehicle_id INT PRIMARY KEY AUTO_INCREMENT,
    driver_id INT NOT NULL,
    vehicle_type ENUM('tricycle', 'motorcycle') DEFAULT 'tricycle',
    brand VARCHAR(50),
    model VARCHAR(50),
    year_model YEAR,
    plate_number VARCHAR(20) UNIQUE,
    or_number VARCHAR(50),
    cr_number VARCHAR(50),
    color VARCHAR(30),
    status ENUM('active', 'inactive', 'maintenance') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (driver_id) REFERENCES drivers(driver_id) ON DELETE CASCADE,
    INDEX idx_vehicle_plate (plate_number),
    INDEX idx_vehicle_status (status)
);

-- Table: gps_devices
CREATE TABLE gps_devices (
    device_id INT PRIMARY KEY AUTO_INCREMENT,
    device_code VARCHAR(20) UNIQUE NOT NULL, -- Format: GPS-001
    sim_number VARCHAR(20) UNIQUE NOT NULL,
    imei_number VARCHAR(20) UNIQUE,
    device_model VARCHAR(50),
    vehicle_id INT NOT NULL,
    activation_code VARCHAR(10) DEFAULT '777',
    is_activated BOOLEAN DEFAULT FALSE,
    activation_date DATETIME,
    status ENUM('active', 'inactive', 'maintenance', 'replaced') DEFAULT 'inactive',
    tracking_enabled BOOLEAN DEFAULT FALSE,
    tracking_expiry DATETIME,
    last_communication DATETIME,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id) ON DELETE CASCADE,
    INDEX idx_sim_number (sim_number),
    INDEX idx_device_status (status),
    INDEX idx_tracking_enabled (tracking_enabled)
);

-- Table: location_updates
CREATE TABLE location_updates (
    location_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    device_id INT NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    accuracy DECIMAL(5, 2), -- Accuracy in meters
    speed DECIMAL(5, 2), -- Speed in km/h
    heading DECIMAL(5, 2), -- Direction in degrees
    altitude DECIMAL(8, 2), -- Altitude in meters
    is_in_terminal BOOLEAN DEFAULT FALSE,
    battery_level INT, -- Battery percentage
    signal_strength INT, -- Signal strength percentage
    recorded_at DATETIME NOT NULL,
    received_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (device_id) REFERENCES gps_devices(device_id) ON DELETE CASCADE,
    INDEX idx_location_device (device_id),
    INDEX idx_location_time (recorded_at),
    INDEX idx_terminal_status (is_in_terminal),
    INDEX idx_location_coords (latitude, longitude)
);

-- Table: tracking_sessions
CREATE TABLE tracking_sessions (
    session_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    device_id INT NOT NULL,
    session_start DATETIME NOT NULL,
    session_end DATETIME,
    entry_location_id BIGINT, -- First location when entered terminal
    exit_location_id BIGINT, -- Last location when left terminal
    total_distance DECIMAL(8, 2) DEFAULT 0, -- Total distance in meters
    max_speed DECIMAL(5, 2) DEFAULT 0, -- Maximum speed in km/h
    avg_speed DECIMAL(5, 2) DEFAULT 0, -- Average speed in km/h
    duration_seconds INT DEFAULT 0, -- Session duration in seconds
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (device_id) REFERENCES gps_devices(device_id) ON DELETE CASCADE,
    FOREIGN KEY (entry_location_id) REFERENCES location_updates(location_id),
    FOREIGN KEY (exit_location_id) REFERENCES location_updates(location_id),
    INDEX idx_session_device (device_id),
    INDEX idx_session_time (session_start),
    INDEX idx_session_duration (duration_seconds)
);

-- Table: sms_messages
CREATE TABLE sms_messages (
    message_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    device_id INT NOT NULL,
    message_type ENUM('location_request', 'emergency_alert', 'driver_message', 'system_message') DEFAULT 'location_request',
    message_text TEXT,
    sender_number VARCHAR(20),
    recipient_number VARCHAR(20),
    direction ENUM('incoming', 'outgoing') DEFAULT 'outgoing',
    status ENUM('sent', 'delivered', 'failed', 'received') DEFAULT 'sent',
    sent_at DATETIME,
    delivered_at DATETIME,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (device_id) REFERENCES gps_devices(device_id) ON DELETE CASCADE,
    INDEX idx_message_device (device_id),
    INDEX idx_message_type (message_type),
    INDEX idx_message_time (sent_at),
    INDEX idx_message_status (status)
);

-- Table: emergency_alerts
CREATE TABLE emergency_alerts (
    alert_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    device_id INT NOT NULL,
    alert_type ENUM('sos', 'accident', 'breakdown', 'medical', 'other') DEFAULT 'sos',
    location_id BIGINT,
    message TEXT,
    priority ENUM('low', 'medium', 'high', 'critical') DEFAULT 'medium',
    status ENUM('pending', 'acknowledged', 'resolved', 'cancelled') DEFAULT 'pending',
    acknowledged_by INT,
    acknowledged_at DATETIME,
    resolved_at DATETIME,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (device_id) REFERENCES gps_devices(device_id) ON DELETE CASCADE,
    FOREIGN KEY (location_id) REFERENCES location_updates(location_id),
    FOREIGN KEY (acknowledged_by) REFERENCES administrators(admin_id),
    INDEX idx_alert_device (device_id),
    INDEX idx_alert_status (status),
    INDEX idx_alert_priority (priority),
    INDEX idx_alert_time (created_at)
);

-- Table: system_settings
CREATE TABLE system_settings (
    setting_id INT PRIMARY KEY AUTO_INCREMENT,
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value TEXT NOT NULL,
    setting_type ENUM('string', 'number', 'boolean', 'json') DEFAULT 'string',
    description TEXT,
    is_public BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_setting_key (setting_key)
);

-- Table: activity_logs
CREATE TABLE activity_logs (
    log_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    admin_id INT,
    activity_type VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (admin_id) REFERENCES administrators(admin_id) ON DELETE SET NULL,
    INDEX idx_activity_type (activity_type),
    INDEX idx_activity_time (created_at)
);

-- Table: fare_transactions
CREATE TABLE fare_transactions (
    transaction_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    driver_id INT NOT NULL,
    terminal_id INT NOT NULL,
    amount DECIMAL(8, 2) NOT NULL,
    transaction_type ENUM('fare_payment', 'terminal_fee', 'penalty', 'refund') DEFAULT 'terminal_fee',
    payment_method ENUM('cash', 'digital', 'card') DEFAULT 'cash',
    status ENUM('pending', 'completed', 'failed', 'refunded') DEFAULT 'completed',
    transaction_date DATETIME NOT NULL,
    notes TEXT,
    created_by INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (driver_id) REFERENCES drivers(driver_id),
    FOREIGN KEY (terminal_id) REFERENCES terminals(terminal_id),
    FOREIGN KEY (created_by) REFERENCES administrators(admin_id),
    INDEX idx_transaction_driver (driver_id),
    INDEX idx_transaction_terminal (terminal_id),
    INDEX idx_transaction_date (transaction_date)
);

-- Insert initial data
INSERT INTO administrators (username, password_hash, full_name, email, role) VALUES
('admin', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'System Administrator', 'admin@fti-arcasouth.com', 'super_admin');

INSERT INTO terminals (terminal_code, terminal_name, address, contact_number, manager_name) VALUES
('FTI-001', 'FTI ARCA SOUTH Terminal', 'FTI Complex, Taguig City', '+63288881234', 'Juan Dela Cruz');

INSERT INTO terminal_geofence (terminal_id, center_latitude, center_longitude, radius_meters, created_by) VALUES
(1, 14.506908, 121.041080, 500, 1);

-- Insert system settings
INSERT INTO system_settings (setting_key, setting_value, setting_type, description, is_public) VALUES
('tracking_interval', '30', 'number', 'GPS location polling interval in seconds', TRUE),
('tracking_duration', '3600', 'number', 'Tracking duration after leaving terminal (seconds)', TRUE),
('emergency_contact', '+639171234500', 'string', 'Primary emergency contact number', TRUE),
('system_phone_number', '+639170001234', 'string', 'System phone number for SMS communication', TRUE),
('max_tracking_devices', '100', 'number', 'Maximum number of tracking devices allowed', TRUE),
('auto_polling_enabled', 'true', 'boolean', 'Enable automatic location polling', TRUE),
('map_default_zoom', '16', 'number', 'Default map zoom level', TRUE),
('data_retention_days', '90', 'number', 'Number of days to keep location data', FALSE),
('terminal_fee_amount', '50.00', 'number', 'Standard terminal fee amount', TRUE),
('sms_api_url', 'https://api.sms-gateway.com/send', 'string', 'SMS gateway API URL', FALSE),
('sms_api_key', 'your-api-key-here', 'string', 'SMS gateway API key', FALSE);

-- Insert sample drivers and devices for testing
INSERT INTO drivers (driver_code, full_name, phone_number, license_number, photo_url, terminal_id) VALUES
('DRV-001', 'Juan Dela Cruz', '+639171234567', 'L123456789', 'https://randomuser.me/api/portraits/men/1.jpg', 1),
('DRV-002', 'Pedro Santos', '+639171234568', 'L123456790', 'https://randomuser.me/api/portraits/men/2.jpg', 1),
('DRV-003', 'Maria Reyes', '+639171234569', 'L123456791', 'https://randomuser.me/api/portraits/women/1.jpg', 1);

INSERT INTO vehicles (driver_id, vehicle_type, brand, model, plate_number, color) VALUES
(1, 'tricycle', 'Honda', 'TMX 155', 'ABC123', 'Red'),
(2, 'tricycle', 'Yamaha', 'Sniper 150', 'ABC124', 'Blue'),
(3, 'tricycle', 'Suzuki', 'Raider 150', 'ABC125', 'Black');

INSERT INTO gps_devices (device_code, sim_number, imei_number, device_model, vehicle_id, is_activated, activation_date, status, tracking_enabled) VALUES
('GPS-001', '+639171234567', '123456789012345', 'Tracker Mini V2', 1, TRUE, NOW(), 'active', TRUE),
('GPS-002', '+639171234568', '123456789012346', 'Tracker Mini V2', 2, TRUE, NOW(), 'active', TRUE),
('GPS-003', '+639171234569', '123456789012347', 'Tracker Mini V2', 3, TRUE, NOW(), 'active', TRUE);

-- Create views for common queries

-- View: active_drivers_locations
CREATE VIEW active_drivers_locations AS
SELECT 
    d.driver_id,
    d.driver_code,
    d.full_name,
    d.phone_number,
    d.photo_url,
    v.vehicle_id,
    v.brand,
    v.model,
    v.plate_number,
    g.device_id,
    g.device_code,
    g.sim_number,
    lu.latitude,
    lu.longitude,
    lu.accuracy,
    lu.speed,
    lu.heading,
    lu.is_in_terminal,
    lu.battery_level,
    lu.signal_strength,
    lu.recorded_at,
    g.tracking_enabled,
    g.tracking_expiry,
    t.terminal_name
FROM drivers d
JOIN vehicles v ON d.driver_id = v.driver_id
JOIN gps_devices g ON v.vehicle_id = g.vehicle_id
JOIN terminals t ON d.terminal_id = t.terminal_id
LEFT JOIN location_updates lu ON g.device_id = lu.device_id
WHERE g.tracking_enabled = TRUE
AND g.status = 'active'
AND d.status = 'active'
AND v.status = 'active'
AND lu.recorded_at = (
    SELECT MAX(recorded_at) 
    FROM location_updates 
    WHERE device_id = g.device_id
);

-- View: terminal_activity_summary
CREATE VIEW terminal_activity_summary AS
SELECT 
    t.terminal_name,
    DATE(lu.recorded_at) as activity_date,
    COUNT(DISTINCT g.device_id) as unique_devices,
    COUNT(lu.location_id) as location_updates,
    AVG(lu.speed) as avg_speed,
    MAX(lu.speed) as max_speed,
    SUM(CASE WHEN lu.is_in_terminal = TRUE THEN 1 ELSE 0 END) as terminal_entries
FROM location_updates lu
JOIN gps_devices g ON lu.device_id = g.device_id
JOIN vehicles v ON g.vehicle_id = v.vehicle_id
JOIN drivers d ON v.driver_id = d.driver_id
JOIN terminals t ON d.terminal_id = t.terminal_id
WHERE lu.recorded_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
GROUP BY t.terminal_id, DATE(lu.recorded_at)
ORDER BY activity_date DESC;

-- Create stored procedures

-- Procedure: Activate GPS Device
DELIMITER //
CREATE PROCEDURE ActivateGPSDevice(
    IN p_sim_number VARCHAR(20),
    IN p_activation_code VARCHAR(10)
)
BEGIN
    DECLARE device_count INT;
    
    SELECT COUNT(*) INTO device_count 
    FROM gps_devices 
    WHERE sim_number = p_sim_number;
    
    IF device_count = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Device not found';
    END IF;
    
    UPDATE gps_devices 
    SET 
        is_activated = TRUE,
        activation_date = NOW(),
        status = 'active',
        tracking_enabled = TRUE,
        tracking_expiry = DATE_ADD(NOW(), INTERVAL 1 HOUR)
    WHERE sim_number = p_sim_number 
    AND activation_code = p_activation_code
    AND is_activated = FALSE;
    
    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid activation code or device already activated';
    END IF;
    
    -- Log the activation
    INSERT INTO activity_logs (activity_type, description) 
    VALUES ('device_activation', CONCAT('GPS device activated: ', p_sim_number));
END//
DELIMITER ;

-- Procedure: Update Device Location
DELIMITER //
CREATE PROCEDURE UpdateDeviceLocation(
    IN p_sim_number VARCHAR(20),
    IN p_latitude DECIMAL(10, 8),
    IN p_longitude DECIMAL(11, 8),
    IN p_accuracy DECIMAL(5, 2),
    IN p_speed DECIMAL(5, 2),
    IN p_heading DECIMAL(5, 2),
    IN p_battery_level INT,
    IN p_signal_strength INT
)
BEGIN
    DECLARE v_device_id INT;
    DECLARE v_is_in_terminal BOOLEAN;
    DECLARE v_previous_in_terminal BOOLEAN;
    DECLARE v_terminal_lat DECIMAL(10, 8);
    DECLARE v_terminal_lng DECIMAL(11, 8);
    DECLARE v_terminal_radius INT;
    
    -- Get device ID
    SELECT device_id INTO v_device_id 
    FROM gps_devices 
    WHERE sim_number = p_sim_number 
    AND is_activated = TRUE 
    AND status = 'active';
    
    IF v_device_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Device not found or not activated';
    END IF;
    
    -- Get terminal geofence settings
    SELECT center_latitude, center_longitude, radius_meters 
    INTO v_terminal_lat, v_terminal_lng, v_terminal_radius
    FROM terminal_geofence 
    WHERE is_active = TRUE 
    ORDER BY geofence_id DESC 
    LIMIT 1;
    
    -- Calculate if location is within terminal
    SET v_is_in_terminal = (
        ST_Distance_Sphere(
            point(p_longitude, p_latitude),
            point(v_terminal_lng, v_terminal_lat)
        ) <= v_terminal_radius
    );
    
    -- Get previous terminal status
    SELECT is_in_terminal INTO v_previous_in_terminal
    FROM location_updates
    WHERE device_id = v_device_id
    ORDER BY recorded_at DESC
    LIMIT 1;
    
    -- Insert location update
    INSERT INTO location_updates (
        device_id, latitude, longitude, accuracy, speed, heading,
        battery_level, signal_strength, is_in_terminal, recorded_at
    ) VALUES (
        v_device_id, p_latitude, p_longitude, p_accuracy, p_speed, p_heading,
        p_battery_level, p_signal_strength, v_is_in_terminal, NOW()
    );
    
    -- Update device last communication
    UPDATE gps_devices 
    SET last_communication = NOW() 
    WHERE device_id = v_device_id;
    
    -- Handle terminal entry/exit
    IF v_previous_in_terminal = FALSE AND v_is_in_terminal = TRUE THEN
        -- Driver entered terminal, extend tracking
        UPDATE gps_devices 
        SET tracking_enabled = TRUE,
            tracking_expiry = DATE_ADD(NOW(), INTERVAL 1 HOUR)
        WHERE device_id = v_device_id;
        
        -- Start new tracking session
        INSERT INTO tracking_sessions (device_id, session_start, entry_location_id)
        VALUES (v_device_id, NOW(), LAST_INSERT_ID());
        
    ELSEIF v_previous_in_terminal = TRUE AND v_is_in_terminal = FALSE THEN
        -- Driver left terminal, update session
        UPDATE tracking_sessions 
        SET session_end = NOW(),
            exit_location_id = LAST_INSERT_ID(),
            duration_seconds = TIMESTAMPDIFF(SECOND, session_start, NOW())
        WHERE device_id = v_device_id 
        AND session_end IS NULL;
    END IF;
    
    -- Log the location update
    INSERT INTO activity_logs (activity_type, description) 
    VALUES ('location_update', CONCAT('Location updated for device: ', p_sim_number));
END//
DELIMITER ;

-- Procedure: Get Active Tracking Devices
DELIMITER //
CREATE PROCEDURE GetActiveTrackingDevices()
BEGIN
    SELECT 
        g.device_code,
        g.sim_number,
        d.full_name,
        d.phone_number,
        v.plate_number,
        v.brand,
        v.model,
        lu.latitude,
        lu.longitude,
        lu.recorded_at,
        lu.is_in_terminal,
        g.tracking_expiry,
        TIMESTAMPDIFF(SECOND, NOW(), g.tracking_expiry) as seconds_remaining
    FROM gps_devices g
    JOIN vehicles v ON g.vehicle_id = v.vehicle_id
    JOIN drivers d ON v.driver_id = d.driver_id
    LEFT JOIN location_updates lu ON g.device_id = lu.device_id
    WHERE g.tracking_enabled = TRUE
    AND g.status = 'active'
    AND lu.recorded_at = (
        SELECT MAX(recorded_at) 
        FROM location_updates 
        WHERE device_id = g.device_id
    )
    ORDER BY lu.recorded_at DESC;
END//
DELIMITER ;

-- Create triggers

-- Trigger: Update tracking_expiry when device enters terminal
DELIMITER //
CREATE TRIGGER after_location_update_enter_terminal
AFTER INSERT ON location_updates
FOR EACH ROW
BEGIN
    DECLARE v_previous_in_terminal BOOLEAN;
    
    -- Get previous terminal status
    SELECT is_in_terminal INTO v_previous_in_terminal
    FROM location_updates
    WHERE device_id = NEW.device_id
    AND location_id != NEW.location_id
    ORDER BY recorded_at DESC
    LIMIT 1;
    
    -- If device just entered terminal, extend tracking
    IF (v_previous_in_terminal IS NULL OR v_previous_in_terminal = FALSE) AND NEW.is_in_terminal = TRUE THEN
        UPDATE gps_devices 
        SET tracking_expiry = DATE_ADD(NOW(), INTERVAL 1 HOUR)
        WHERE device_id = NEW.device_id;
    END IF;
END//
DELIMITER ;

-- Trigger: Log device status changes
DELIMITER //
CREATE TRIGGER after_gps_device_update
AFTER UPDATE ON gps_devices
FOR EACH ROW
BEGIN
    IF OLD.tracking_enabled != NEW.tracking_enabled THEN
        INSERT INTO activity_logs (activity_type, description)
        VALUES (
            'tracking_status_change',
            CONCAT('Device ', NEW.device_code, ' tracking ', 
                   CASE WHEN NEW.tracking_enabled THEN 'enabled' ELSE 'disabled' END)
        );
    END IF;
    
    IF OLD.status != NEW.status THEN
        INSERT INTO activity_logs (activity_type, description)
        VALUES (
            'device_status_change',
            CONCAT('Device ', NEW.device_code, ' status changed from ', 
                   OLD.status, ' to ', NEW.status)
        );
    END IF;
END//
DELIMITER ;

-- Create indexes for better performance
CREATE INDEX idx_location_updates_device_recorded ON location_updates(device_id, recorded_at);
CREATE INDEX idx_gps_devices_tracking ON gps_devices(tracking_enabled, status, tracking_expiry);
CREATE INDEX idx_sms_messages_device_status ON sms_messages(device_id, status, sent_at);
CREATE INDEX idx_emergency_alerts_status_priority ON emergency_alerts(status, priority, created_at);

-- Display table information
SELECT 
    TABLE_NAME,
    TABLE_ROWS,
    DATA_LENGTH,
    INDEX_LENGTH,
    CREATE_TIME
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'fti_terminal_db'
ORDER BY TABLE_NAME;

-- Show created views
SHOW FULL TABLES WHERE TABLE_TYPE = 'VIEW';

-- Show stored procedures
SHOW PROCEDURE STATUS WHERE Db = 'fti_terminal_db';

-- Show triggers
SHOW TRIGGERS FROM fti_terminal_db;