"use client";

import { useEffect, useMemo, useState } from "react";
import { supabase } from "@/lib/supabase";

type Book = {
  id: string;
  title: string;
  author: string;
  category: string;
  isbn: string | null;
  copies_total: number;
  copies_available: number;
};

const demoBooks: Book[] = [
  { id: "demo-1", title: "Clean Code", author: "Robert C. Martin", category: "Software Engineering", isbn: "9780132350884", copies_total: 5, copies_available: 3 },
  { id: "demo-2", title: "Introduction to Algorithms", author: "Cormen et al.", category: "Algorithms", isbn: "9780262046305", copies_total: 4, copies_available: 2 },
  { id: "demo-3", title: "Artificial Intelligence: A Modern Approach", author: "Russell & Norvig", category: "Artificial Intelligence", isbn: "9780134610993", copies_total: 3, copies_available: 2 },
  { id: "demo-4", title: "Computer Networking", author: "Kurose & Ross", category: "Computer Networks", isbn: "9780136681557", copies_total: 4, copies_available: 4 }
];

export default function Home() {
  const [books, setBooks] = useState<Book[]>(demoBooks);
  const [search, setSearch] = useState("");
  const [category, setCategory] = useState("All categories");
  const [status, setStatus] = useState("Connecting to catalogue…");
  const [showAdd, setShowAdd] = useState(false);
  const [title, setTitle] = useState("");
  const [author, setAuthor] = useState("");
  const [bookCategory, setBookCategory] = useState("Computer Science");
  const [isbn, setIsbn] = useState("");

  async function loadBooks() {
    if (!supabase) {
      setStatus("Preview mode · add Supabase environment variables to enable database storage");
      return;
    }
    const { data, error } = await supabase.from("books").select("id,title,author,category,isbn,copies_total,copies_available").order("title");
    if (error) {
      setStatus("Supabase configured · database setup or access policies still required");
      return;
    }
    setBooks((data as Book[]) ?? []);
    setStatus("Connected to Supabase");
  }

  useEffect(() => { void loadBooks(); }, []);

  const categories = useMemo(() => ["All categories", ...Array.from(new Set(books.map(b => b.category)))], [books]);
  const filtered = books.filter(book =>
    (category === "All categories" || book.category === category) &&
    [book.title, book.author, book.category, book.isbn ?? ""].some(v => v.toLowerCase().includes(search.toLowerCase()))
  );

  async function addBook(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    if (!title.trim() || !author.trim()) return;
    if (!supabase) {
      const item: Book = { id: crypto.randomUUID(), title: title.trim(), author: author.trim(), category: bookCategory, isbn: isbn.trim() || null, copies_total: 1, copies_available: 1 };
      setBooks(current => [...current, item]);
      setStatus("Added in this preview session only · configure Supabase for persistent storage");
    } else {
      const { error } = await supabase.from("books").insert({ title: title.trim(), author: author.trim(), category: bookCategory, isbn: isbn.trim() || null, copies_total: 1, copies_available: 1 });
      if (error) { setStatus(`Could not save book: ${error.message}`); return; }
      await loadBooks();
    }
    setTitle(""); setAuthor(""); setIsbn(""); setShowAdd(false);
  }

  return (
    <main className="shell">
      <aside className="sidebar">
        <div className="brand"><div className="brand-mark">N</div><div><strong>NEXTLIB</strong><small>COMPUTER SCIENCE</small></div></div>
        <p className="nav-label">LIBRARY WORKSPACE</p>
        <button className="nav-item active"><span>▦</span> Overview</button>
        <button className="nav-item" onClick={() => document.getElementById("catalogue")?.scrollIntoView({ behavior: "smooth" })}><span>▤</span> Book catalogue</button>
        <button className="nav-item" onClick={() => setStatus("Member management is part of the next integration step.")}><span>♙</span> Members</button>
        <button className="nav-item" onClick={() => setStatus("Circulation management is part of the next integration step.")}><span>↔</span> Loans & returns</button>
        <button className="nav-item" onClick={() => setStatus("Reports are not enabled in this starter package.")}><span>▥</span> Reports</button>
        <div className="sidebar-foot"><div className="avatar">CS</div><div><b>Library Admin</b><small>Computer Science</small></div></div>
      </aside>
      <section className="main">
        <header className="topbar"><div><span className="eyebrow">LIBRARY MANAGEMENT</span><h1>Overview</h1></div><div className="top-actions"><span className="status-dot" /> <span className="connection">{status}</span></div></header>
        <div className="welcome"><div><p className="eyebrow light">YOUR KNOWLEDGE HUB</p><h2>Welcome to NEXTLIB</h2><p>Manage your Computer Science collection, discover resources, and keep your library organised.</p></div><div className="welcome-art">N<span>+</span></div></div>
        <div className="stats">
          <article className="stat-card"><span className="stat-icon blue">▤</span><div><p>Total titles</p><strong>{books.length}</strong><small>In the catalogue</small></div></article>
          <article className="stat-card"><span className="stat-icon green">✓</span><div><p>Available copies</p><strong>{books.reduce((n,b) => n + b.copies_available, 0)}</strong><small>Ready to borrow</small></div></article>
          <article className="stat-card"><span className="stat-icon violet">⌕</span><div><p>Categories</p><strong>{new Set(books.map(b => b.category)).size}</strong><small>Subject areas</small></div></article>
        </div>
        <section className="catalogue" id="catalogue">
          <div className="section-head"><div><h2>Book catalogue</h2><p>Search and manage your library collection.</p></div><button className="primary" onClick={() => setShowAdd(v => !v)}>＋ Add a book</button></div>
          {showAdd && <form className="add-form" onSubmit={addBook}>
            <label>Book title<input value={title} onChange={e => setTitle(e.target.value)} required placeholder="Enter book title" /></label>
            <label>Author<input value={author} onChange={e => setAuthor(e.target.value)} required placeholder="Enter author" /></label>
            <label>Category<input value={bookCategory} onChange={e => setBookCategory(e.target.value)} required /></label>
            <label>ISBN<input value={isbn} onChange={e => setIsbn(e.target.value)} placeholder="Optional ISBN" /></label>
            <button className="primary" type="submit">Save book</button>
          </form>}
          <div className="filters"><input aria-label="Search catalogue" placeholder="Search by title, author, ISBN…" value={search} onChange={e => setSearch(e.target.value)} /><select aria-label="Filter category" value={category} onChange={e => setCategory(e.target.value)}>{categories.map(c => <option key={c}>{c}</option>)}</select></div>
          <div className="table-wrap"><table><thead><tr><th>BOOK TITLE</th><th>CATEGORY</th><th>ISBN</th><th>COPIES</th><th>AVAILABILITY</th></tr></thead><tbody>
            {filtered.map(book => <tr key={book.id}><td><div className="book-title"><div className="book-icon">▤</div><div><b>{book.title}</b><small>{book.author}</small></div></div></td><td>{book.category}</td><td className="isbn">{book.isbn || "—"}</td><td>{book.copies_total}</td><td><span className={book.copies_available ? "pill available" : "pill unavailable"}>{book.copies_available} available</span></td></tr>)}
            {!filtered.length && <tr><td colSpan={5} className="empty">No books match your search.</td></tr>}
          </tbody></table></div>
          <div className="table-foot">Showing {filtered.length} of {books.length} titles <button onClick={() => { setSearch(""); setCategory("All categories"); }}>Clear filters</button></div>
        </section>
        <footer>© {new Date().getFullYear()} NEXTLIB · Computer Science Library <span>Knowledge for everyone.</span></footer>
      </section>
    </main>
  );
}
