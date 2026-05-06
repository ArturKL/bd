// Скрипт для домашней работы MongoDB (выполняется: mongosh ... --file hw-commands.js)
db = db.getSiblingDB("hw");
db.books.drop();

print("\n========== 1. Коллекция books, один документ ==========\n");
db.books.insertOne({
  title: "Эффективный JavaScript",
  genre: "programming",
  price: 42,
  available: true,
  tags: ["javascript", "best-practices"],
  author: { name: "David Herman", country: "USA" },
});
printjson(db.books.find().toArray());

print("\n========== 2. Все книги в наличии (available: true) ==========\n");
db.books.find({ available: true }).forEach((doc) => printjson(doc));

print("\n========== 3. Добавление ещё нескольких книг ==========\n");
db.books.insertMany([
  {
    title: "Преступление и наказание",
    genre: "classic",
    price: 15,
    available: true,
    tags: ["russian", "novel", "psychology"],
    author: { name: "Фёдор Достоевский", country: "Russia" },
  },
  {
    title: "Дюна",
    genre: "sci-fi",
    price: 22,
    available: false,
    tags: ["space", "epic"],
    author: { name: "Frank Herbert", country: "USA" },
  },
  {
    title: "Python к вершинам мастерства",
    genre: "programming",
    price: 65,
    available: true,
    tags: ["python", "tutorial"],
    author: { name: "Luciano Ramalho", country: "Brazil" },
  },
  {
    title: "Готовим дома просто и вкусно",
    genre: "cooking",
    price: 9,
    available: true,
    tags: ["recipes", "home"],
    author: { name: "Иван Петров", country: "Russia" },
  },
  {
    title: "Введение в алгоритмы",
    genre: "programming",
    price: 95,
    available: false,
    tags: ["algorithms", "cs"],
    author: { name: "Thomas Cormen", country: "USA" },
  },
  {
    title: "Выразительный JavaScript",
    genre: "programming",
    price: 38,
    available: true,
    tags: ["javascript", "beginner"],
    author: { name: "Marijn Haverbeke", country: "Netherlands" },
  },
]);

printjson(db.books.find().toArray());

const priceThreshold = 40;
print(
  `\n========== 4. programming, цена > ${priceThreshold}, в наличии; только title и price ==========\n`
);
db.books
  .find(
    { genre: "programming", price: { $gt: priceThreshold }, available: true },
    { _id: 0, title: 1, price: 1 }
  )
  .forEach((doc) => printjson(doc));

print("\n--- готово ---\n");
