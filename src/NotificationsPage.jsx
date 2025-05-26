import React from "react";
import { supabase } from "./supabaseClient";

export default function NotificationsPage({
  notifications,
  setNotifications,
  setUnreadCount,
}) {
  // Mark a single notification as read
  const markAsRead = async (id) => {
    await supabase.from("notifications").update({ read: true }).eq("id", id);
    const updated = notifications.map((n) =>
      n.id === id ? { ...n, read: true } : n
    );
    setNotifications(updated);
    setUnreadCount(updated.filter((n) => !n.read).length);
  };

  // Mark all as read
  const markAllAsRead = async () => {
    const unreadIds = notifications.filter((n) => !n.read).map((n) => n.id);
    if (unreadIds.length === 0) return;
    await supabase
      .from("notifications")
      .update({ read: true })
      .in("id", unreadIds);
    const updated = notifications.map((n) => ({ ...n, read: true }));
    setNotifications(updated);
    setUnreadCount(0);
  };

  // Delete a single notification
  const deleteNotification = async (id) => {
    await supabase.from("notifications").delete().eq("id", id);
    const updated = notifications.filter((n) => n.id !== id);
    setNotifications(updated);
    setUnreadCount(updated.filter((n) => !n.read).length);
  };

  // Delete all notifications
  const deleteAll = async () => {
    const allIds = notifications.map((n) => n.id);
    if (allIds.length === 0) return;
    await supabase.from("notifications").delete().in("id", allIds);
    setNotifications([]);
    setUnreadCount(0);
  };

  return (
    <div style={{ maxWidth: 700, margin: "0 auto", padding: 32 }}>
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          marginBottom: 24,
        }}
      >
        <h2 style={{ margin: 0 }}>Notifications</h2>
        <div style={{ display: "flex", gap: 8 }}>
          <button
            className="button secondary"
            onClick={markAllAsRead}
            disabled={notifications.every((n) => n.read)}
          >
            Mark all as read
          </button>
          <button
            className="button danger"
            onClick={deleteAll}
            disabled={notifications.length === 0}
          >
            Delete all
          </button>
        </div>
      </div>
      {notifications.length === 0 ? (
        <div style={{ color: "#888", textAlign: "center", marginTop: 80 }}>
          No notifications yet.
        </div>
      ) : (
        <ul
          style={{
            listStyle: "none",
            padding: 0,
            margin: 0,
            maxHeight: 600,
            overflowY: "auto",
          }}
        >
          {notifications.map((n) => (
            <li
              key={n.id}
              style={{
                marginBottom: 20,
                borderBottom: "1px solid #eee",
                paddingBottom: 12,
                background: n.read ? "#f7f7f7" : "#fffde7",
                position: "relative",
                borderRadius: 4,
                boxShadow: n.read
                  ? "none"
                  : "0 2px 8px rgba(255, 235, 59, 0.08)",
              }}
            >
              <div style={{ fontSize: 15, fontWeight: n.read ? 400 : 600 }}>
                {n.message}
              </div>
              {n.products?.name && (
                <div style={{ fontSize: 13, color: "#1976d2", marginTop: 2 }}>
                  Product: {n.products.name}
                </div>
              )}
              <div style={{ fontSize: 12, color: "#888", marginTop: 4 }}>
                {new Date(n.created_at).toLocaleString()}
              </div>
              <div
                style={{
                  position: "absolute",
                  top: 8,
                  right: 8,
                  display: "flex",
                  gap: 8,
                }}
              >
                {!n.read && (
                  <button
                    className="button secondary"
                    style={{ fontSize: 12, padding: "2px 8px" }}
                    onClick={() => markAsRead(n.id)}
                  >
                    Mark as read
                  </button>
                )}
                <button
                  className="button danger"
                  style={{ fontSize: 12, padding: "2px 8px" }}
                  onClick={() => deleteNotification(n.id)}
                >
                  Delete
                </button>
              </div>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
