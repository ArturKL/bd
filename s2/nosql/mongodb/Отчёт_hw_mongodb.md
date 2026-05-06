### Файл `docker-compose.yml`

```yaml
services:
  mongodb:
    image: mongo:7
    ports:
      - "27017:27017"
```

```powershell
docker cp c:\Users\artur\DataGripProjects\bd\s2\nosql\mongodb\hw-commands.js mongodb-mongodb-1:/tmp/hw-commands.js
docker exec mongodb-mongodb-1 mongosh --quiet --file /tmp/hw-commands.js
```

База данных: **`hw`**, коллекция: **`books`**.

Результат:
```javascript
docker exec mongodb-mongodb-1 mongosh --quiet --file /tmp/hw-commands.js
========== 1. Коллекция books, один документ ==========

[
  {
    _id: ObjectId('69fa701d8905a4d81244ba89'),
    title: 'Эффективный JavaScript',
    genre: 'programming',
    price: 42,
    available: true,
    tags: [
      'javascript',
      'best-practices'
    ],
    author: {
      name: 'David Herman',
      country: 'USA'
    }
  }
]

========== 2. Все книги в наличии (available: true) ==========

{
  _id: ObjectId('69fa701d8905a4d81244ba89'),
  title: 'Эффективный JavaScript',
  genre: 'programming',
  price: 42,
  available: true,
  tags: [
    'javascript',
    'best-practices'
  ],
  author: {
    name: 'David Herman',
    country: 'USA'
  }
}

========== 3. Добавление ещё нескольких книг ==========

[
  {
    _id: ObjectId('69fa701d8905a4d81244ba89'),
    title: 'Эффективный JavaScript',
    genre: 'programming',
    price: 42,
    available: true,
    tags: [
      'javascript',
      'best-practices'
    ],
    author: {
      name: 'David Herman',
      country: 'USA'
    }
  },
  {
    _id: ObjectId('69fa701f8905a4d81244ba8a'),
    title: 'Преступление и наказание',
    genre: 'classic',
    price: 15,
    available: true,
    tags: [
      'russian',
      'novel',
      'psychology'
    ],
    author: {
      name: 'Фёдор Достоевский',
      country: 'Russia'
    }
  },
  {
    _id: ObjectId('69fa701f8905a4d81244ba8b'),
    title: 'Дюна',
    genre: 'sci-fi',
    price: 22,
    available: false,
    tags: [
      'space',
      'epic'
    ],
    author: {
      name: 'Frank Herbert',
      country: 'USA'
    }
  },
  {
    _id: ObjectId('69fa701f8905a4d81244ba8c'),
    title: 'Python к вершинам мастерства',
    genre: 'programming',
    price: 65,
    available: true,
    tags: [
      'python',
      'tutorial'
    ],
    author: {
      name: 'Luciano Ramalho',
      country: 'Brazil'
    }
  },
  {
    _id: ObjectId('69fa701f8905a4d81244ba8d'),
    title: 'Готовим дома просто и вкусно',
    genre: 'cooking',
    price: 9,
    available: true,
    tags: [
      'recipes',
      'home'
    ],
    author: {
      name: 'Иван Петров',
      country: 'Russia'
    }
  },
  {
    _id: ObjectId('69fa701f8905a4d81244ba8e'),
    title: 'Введение в алгоритмы',
    genre: 'programming',
    price: 95,
    available: false,
    tags: [
      'algorithms',
      'cs'
    ],
    author: {
      name: 'Thomas Cormen',
      country: 'USA'
    }
  },
  {
    _id: ObjectId('69fa701f8905a4d81244ba8f'),
    title: 'Выразительный JavaScript',
    genre: 'programming',
    price: 38,
    available: true,
    tags: [
      'javascript',
      'beginner'
    ],
    author: {
      name: 'Marijn Haverbeke',
      country: 'Netherlands'
    }
  }
]

========== 4. programming, цена > 40, в наличии; только title и price ==========

{
  title: 'Эффективный JavaScript',
  price: 42
}
{
  title: 'Python к вершинам мастерства',
  price: 65
}

--- готово ---
```
