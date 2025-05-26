import React, { useEffect, useState } from "react";
import { supabase } from "./supabaseClient";

export default function ProductDashboard() {
  const [products, setProducts] = useState([]);
  const [error, setError] = useState(null);
  const [open, setOpen] = useState(false);
  const [editProduct, setEditProduct] = useState(null);
  const [form, setForm] = useState({
    name: "",
    quantity: 0,
    threshold: 0,
    expired_date: "",
    section: "A",
  });

  // Fetch products
  const fetchProducts = async () => {
    const { data, error } = await supabase
      .from("products")
      .select("*")
      .order("created_at", { ascending: false });
    setProducts(data || []);
    setError(error ? error.message : null);
  };

  useEffect(() => {
    fetchProducts();
    const interval = setInterval(() => {
      fetchProducts();
    }, 1000);
    return () => clearInterval(interval);
  });

  // Handle form open/close
  const handleOpen = (product = null) => {
    setEditProduct(product);
    setForm(
      product
        ? {
            ...product,
            expired_date: product.expired_date
              ? product.expired_date.split("T")[0]
              : "",
            section: product.section || "A",
          }
        : {
            name: "",
            quantity: 0,
            threshold: 0,
            expired_date: "",
            section: "A",
          }
    );
    setOpen(true);
  };
  const handleClose = () => {
    setOpen(false);
    setEditProduct(null);
    setForm({
      name: "",
      quantity: 0,
      threshold: 0,
      expired_date: "",
      section: "A",
    });
  };

  // Handle form change
  const handleChange = (e) => {
    const { name, value } = e.target;
    setForm((prev) => ({ ...prev, [name]: value }));
  };

  // Add or update product
  const handleSubmit = async (e) => {
    e.preventDefault();
    if (editProduct) {
      // Update
      const oldQuantity = editProduct.quantity;
      const newQuantity = Number(form.quantity);
      // Fetch last_notified_quantity from the DB
      const { data: productRow } = await supabase
        .from("products")
        .select("last_notified_quantity")
        .eq("id", editProduct.id)
        .single();
      const lastNotified = productRow?.last_notified_quantity;
      const { error } = await supabase
        .from("products")
        .update({
          name: form.name,
          quantity: newQuantity,
          threshold: Number(form.threshold),
          expired_date: form.expired_date || null,
          section: form.section,
        })
        .eq("id", editProduct.id);
      setError(error ? error.message : null);
      // Notification logic
      if (oldQuantity !== newQuantity && newQuantity !== lastNotified) {
        let changeType = newQuantity > oldQuantity ? "increased" : "decreased";
        let diff = Math.abs(newQuantity - oldQuantity);
        let message = `Quantity of '${form.name}' was ${changeType} by ${diff}. New quantity: ${newQuantity}.`;
        await supabase.from("notifications").insert([
          {
            product_id: editProduct.id,
            message,
          },
        ]);
        // Update last_notified_quantity
        await supabase
          .from("products")
          .update({ last_notified_quantity: newQuantity })
          .eq("id", editProduct.id);
      }
    } else {
      // Add
      const { error } = await supabase.from("products").insert([
        {
          name: form.name,
          quantity: Number(form.quantity),
          threshold: Number(form.threshold),
          expired_date: form.expired_date || null,
          section: form.section,
        },
      ]);
      setError(error ? error.message : null);
    }
    handleClose();
    fetchProducts();
  };

  // Delete product
  const handleDelete = async (id) => {
    const { error } = await supabase.from("products").delete().eq("id", id);
    setError(error ? error.message : null);
    fetchProducts();
  };

  return (
    <div>
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          marginBottom: 16,
        }}
      >
        <h3>Products</h3>
        <button className="button" onClick={() => handleOpen()}>
          Add Product
        </button>
      </div>
      {error && <div className="alert error">{error}</div>}
      <table className="table">
        <thead>
          <tr>
            <th>Name</th>
            <th>Quantity</th>
            <th>Threshold</th>
            <th>Expired Date</th>
            <th>Section</th>
            <th>Created At</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {products.map((product) => (
            <tr key={product.id}>
              <td>
                {product.name}
                {product.quantity < product.threshold && (
                  <div
                    className="alert warning"
                    style={{ marginTop: 8, padding: 4, fontSize: 12 }}
                  >
                    Low Stock
                  </div>
                )}
              </td>
              <td>{product.quantity}</td>
              <td>{product.threshold}</td>
              <td>
                {product.expired_date
                  ? new Date(product.expired_date).toLocaleDateString()
                  : ""}
              </td>
              <td>{product.section}</td>
              <td>{new Date(product.created_at).toLocaleString()}</td>
              <td>
                <button
                  className="button secondary"
                  onClick={() => handleOpen(product)}
                  style={{ marginRight: 4 }}
                >
                  Edit
                </button>
                <button
                  className="button danger"
                  onClick={() => handleDelete(product.id)}
                >
                  Delete
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
      {/* Add/Edit Dialog */}
      {open && (
        <>
          <div className="dialog-backdrop" onClick={handleClose}></div>
          <div className="dialog">
            <div className="dialog-title">
              {editProduct ? "Edit Product" : "Add Product"}
            </div>
            <form onSubmit={handleSubmit}>
              <div className="form-group">
                <label htmlFor="name">Name</label>
                <input
                  id="name"
                  name="name"
                  value={form.name}
                  onChange={handleChange}
                  required
                />
              </div>
              <div className="form-group">
                <label htmlFor="quantity">Quantity</label>
                <input
                  id="quantity"
                  name="quantity"
                  type="number"
                  value={form.quantity}
                  onChange={handleChange}
                  required
                />
              </div>
              <div className="form-group">
                <label htmlFor="threshold">Threshold</label>
                <input
                  id="threshold"
                  name="threshold"
                  type="number"
                  value={form.threshold}
                  onChange={handleChange}
                  required
                />
              </div>
              <div className="form-group">
                <label htmlFor="expired_date">Expired Date</label>
                <input
                  id="expired_date"
                  name="expired_date"
                  type="date"
                  value={form.expired_date}
                  onChange={handleChange}
                />
              </div>
              <div className="form-group">
                <label htmlFor="section">Section</label>
                <select
                  id="section"
                  name="section"
                  value={form.section}
                  onChange={handleChange}
                  required
                >
                  <option value="A">A</option>
                  <option value="B">B</option>
                  <option value="C">C</option>
                </select>
              </div>
              <div className="dialog-actions">
                <button
                  className="button secondary"
                  type="button"
                  onClick={handleClose}
                >
                  Cancel
                </button>
                <button className="button" type="submit">
                  {editProduct ? "Update" : "Add"}
                </button>
              </div>
            </form>
          </div>
        </>
      )}
    </div>
  );
}
