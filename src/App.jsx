import { useEffect, useState } from "react";
import { supabase } from "./supabaseClient";
import Login from "./Login.jsx";
import ProductDashboard from "./ProductDashboard.jsx";
import SensorDashboard from "./SensorDashboard.jsx";
import NotificationsPage from "./NotificationsPage.jsx";

function App() {
  const [session, setSession] = useState(null);
  const [page, setPage] = useState("dashboard");
  const [notifications, setNotifications] = useState([]);
  const [unreadCount, setUnreadCount] = useState(0);

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session);
    });
    const { data: listener } = supabase.auth.onAuthStateChange(
      (_event, session) => {
        setSession(session);
      }
    );
    return () => {
      listener.subscription.unsubscribe();
    };
  }, []);

  // Fetch notifications
  useEffect(() => {
    if (!session) return;
    const fetchNotifications = async () => {
      const { data } = await supabase
        .from("notifications")
        .select("*, products(name)")
        .order("created_at", { ascending: false })
        .limit(50);
      setNotifications(data || []);
      setUnreadCount((data || []).filter((n) => !n.read).length);
    };
    fetchNotifications();
    // Poll every 10 seconds
    const interval = setInterval(fetchNotifications, 10000);
    return () => clearInterval(interval);
  }, [session]);

  const handleLogout = async () => {
    await supabase.auth.signOut();
  };

  if (!session) {
    return (
      <Login
        onLogin={() =>
          supabase.auth
            .getSession()
            .then(({ data: { session } }) => setSession(session))
        }
      />
    );
  }

  return (
    <div style={{ display: "flex", minHeight: "100vh" }}>
      {/* Sidebar */}
      <div
        style={{
          width: 220,
          background: "#222",
          color: "#fff",
          padding: 24,
          display: "flex",
          flexDirection: "column",
          gap: 16,
          position: "relative",
          transition: "width 0.2s",
        }}
      >
        <h2 style={{ color: "#fff", fontSize: 22, marginBottom: 32 }}>
          Inventory
        </h2>
        <button
          className="button secondary"
          style={{
            background: page === "dashboard" ? "#1976d2" : "#e0e0e0",
            color: page === "dashboard" ? "#fff" : "#222",
          }}
          onClick={() => setPage("dashboard")}
        >
          Dashboard
        </button>
        <button
          className="button"
          style={{
            background: page === "notifications" ? "#1976d2" : "#e0e0e0",
            color: page === "notifications" ? "#fff" : "#222",
            position: "relative",
          }}
          onClick={() => setPage("notifications")}
        >
          Notifications
          {unreadCount > 0 && (
            <span
              style={{
                position: "absolute",
                top: 6,
                right: 12,
                background: "#d32f2f",
                color: "#fff",
                borderRadius: "50%",
                padding: "2px 8px",
                fontSize: 12,
                fontWeight: 600,
                marginLeft: 8,
              }}
            >
              {unreadCount}
            </span>
          )}
        </button>
        <div style={{ flex: 1 }} />
        <button className="button danger" onClick={handleLogout}>
          Logout
        </button>
      </div>
      {/* Main Content */}
      <div className="app-container" style={{ flex: 1, minHeight: "100vh" }}>
        {page === "dashboard" && (
          <>
            <h2 style={{ marginBottom: 24 }}>Dashboard</h2>
            <div style={{ display: "flex", flexDirection: "column", gap: 40 }}>
              <div style={{ flex: 2, minWidth: 350 }}>
                <ProductDashboard />
              </div>
              <div style={{ flex: 1, minWidth: 350 }}>
                <SensorDashboard gaugesOnly />
              </div>
            </div>
          </>
        )}
        {page === "notifications" && (
          <NotificationsPage
            notifications={notifications}
            setNotifications={setNotifications}
            setUnreadCount={setUnreadCount}
          />
        )}
      </div>
    </div>
  );
}

export default App;
