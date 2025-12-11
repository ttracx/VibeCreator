<p align="center">
  <img src="./art/vibecaas-logo.png" alt="VibeCreator Logo" width="200" />
</p>

<h1 align="center">VibeCreator</h1>

<p align="center">
  <strong>Vibe Coding as a Service (VibeCaaS)</strong>
</p>

<p align="center">
  <a href="https://vibecaas.com">Website</a> •
  <a href="#features">Features</a> •
  <a href="#installation">Installation</a> •
  <a href="#documentation">Documentation</a> •
  <a href="#contributing">Contributing</a>
</p>

---

## Introduction

**VibeCreator** is a powerful and intuitive **social media management platform** powered by VibeCaaS (Vibe Coding as a Service). Designed to streamline your social media operations, VibeCreator helps brands and businesses effectively manage their online presence and elevate their content marketing strategies.

Our platform empowers you to craft, organize, and schedule content for maximum engagement, all from a single, unified dashboard.

## Features

### 🎯 Streamlined Social Account Management
Bring all your social media accounts together in one place for smarter and more efficient management.

### 📊 Advanced Analytics
Gain insights into your audience's behavior and preferences with detailed analytics for each platform.

### 📝 Post Versions and Conditions
Tailor your content for each social network and automate follow-up comments on high-performing posts.

### 🖼️ Efficient Media Library
Quickly access and reuse media files like images, GIFs, and videos, with integration to stock image sources.

### 👥 Team Collaboration and Workspaces
Foster team collaboration with dedicated workspaces. Discuss ideas, manage tasks, and monitor performance from a centralized platform.

### 📅 Queue and Calendar Management
Build a natural content posting schedule and visualize your strategy with an easy-to-use calendar.

### 📋 Customizable Post Templates
Boost efficiency with reusable post templates for maintaining consistency across your social media channels.

### 🔤 Dynamic Variables and Hashtag Groups
Insert dynamic text and organize your hashtags strategically for increased post effectiveness.

## Installation

### Requirements

- PHP 8.1 or higher
- Laravel 10.x or 11.x
- MySQL 8.0+ or PostgreSQL 13+
- Node.js 18+ and npm
- Composer

### Quick Start

1. Clone the repository:
```bash
git clone https://github.com/ttracx/VibeCreator.git
cd VibeCreator
```

2. Install dependencies:
```bash
composer install
npm install
```

3. Configure environment:
```bash
cp .env.example .env
php artisan key:generate
```

4. Run migrations:
```bash
php artisan migrate
```

5. Build assets:
```bash
npm run build
```

6. Start the development server:
```bash
php artisan serve
```

## Documentation

For detailed documentation, please visit our [documentation site](https://docs.vibecaas.com).

## Platforms Supported

- **Twitter/X** - Post tweets, threads, and media
- **Facebook Pages & Groups** - Manage page content and group posts
- **Mastodon** - Federated social networking support
- **More coming soon!**

## Changelog

Please see [CHANGELOG](CHANGELOG.md) for more information on recent changes.

## Contributing

We welcome contributions! Please read our contributing guidelines before submitting pull requests.

### Guidelines

- Follow the [PSR-12 Coding Standard](https://github.com/php-fig/fig-standards/blob/master/accepted/PSR-12-extended-coding-style-guide.md)
- Write clear commit messages and PR descriptions
- Add tests for new features
- Ensure all tests pass before submitting

## Security Vulnerabilities

Please review [our security policy](SECURITY.md) on how to report security vulnerabilities.

## License

VibeCreator is open-sourced software licensed under the [MIT license](LICENSE.md).

---

<p align="center">
  © 2025 VibeCreator powered by <a href="https://vibecaas.com">VibeCaaS.com</a> a division of <a href="https://neuralquantum.ai">NeuralQuantum.ai</a> LLC. All rights reserved.
</p>
