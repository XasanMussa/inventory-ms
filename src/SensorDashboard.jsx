import React, { useEffect, useState } from "react";
import GaugeChart from "react-gauge-chart";
import { supabase } from "./supabaseClient";

export default function SensorDashboard({ gaugesOnly }) {
  const [sensorData, setSensorData] = useState([]);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchSensorData = async () => {
      const { data, error } = await supabase
        .from("sensor_readings")
        .select("*")
        .order("timestamp", { ascending: false })
        .limit(10);
      setSensorData(data || []);
      setError(error ? error.message : null);
    };
    fetchSensorData();
    // Optionally, poll every 10 seconds
    const interval = setInterval(fetchSensorData, 10000);
    return () => clearInterval(interval);
  }, []);

  // Get latest reading
  const latest = sensorData[0];

  return (
    <div>
      <h3>Sensor Data</h3>
      {error && <div className="alert error">{error}</div>}
      {latest ? (
        <div style={{ display: "flex", gap: 40, flexWrap: "wrap" }}>
          <div style={{ flex: 1, minWidth: 250, textAlign: "center" }}>
            <h4>Temperature</h4>
            <GaugeChart
              id="gauge-temp"
              nrOfLevels={20}
              percent={latest.temperature / 100}
              textColor="#333"
              formatTextValue={() => `${latest.temperature}°C`}
              colors={["#00bcd4", "#ff9800", "#d32f2f"]}
              arcWidth={0.3}
            />
          </div>
          <div style={{ flex: 1, minWidth: 250, textAlign: "center" }}>
            <h4>Humidity</h4>
            <GaugeChart
              id="gauge-humidity"
              nrOfLevels={20}
              percent={latest.humidity / 100}
              textColor="#333"
              formatTextValue={() => `${latest.humidity}%`}
              colors={["#1976d2", "#4caf50", "#ffeb3b"]}
              arcWidth={0.3}
            />
          </div>
        </div>
      ) : (
        <div>No sensor data available.</div>
      )}
      {!gaugesOnly && (
        <div style={{ marginTop: 32 }}>
          <h4>Recent Readings</h4>
          <table className="table">
            <thead>
              <tr>
                <th>Timestamp</th>
                <th>Temperature (°C)</th>
                <th>Humidity (%)</th>
                <th>Product ID</th>
              </tr>
            </thead>
            <tbody>
              {sensorData.map((row) => (
                <tr key={row.id}>
                  <td>{new Date(row.timestamp).toLocaleString()}</td>
                  <td>{row.temperature}</td>
                  <td>{row.humidity}</td>
                  <td>{row.product_id}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
