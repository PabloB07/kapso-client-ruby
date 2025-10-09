# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-01-09

### Added

- Initial release of Kapso API Ruby SDK
- Complete Kapso API support with all message types
- Support for text, image, audio, video, document, sticker, location, and contact messages
- Interactive message support (buttons, lists, product catalogs)
- Template message creation and management
- Media upload, download, and management
- Phone number registration and verification
- Call management and permissions (via Kapso proxy)
- Conversation history and management (via Kapso proxy)
- Contact management with metadata and tagging (via Kapso proxy)
- Comprehensive error handling with categorization and retry hints
- Debug logging with configurable levels
- Automatic retry logic with exponential backoff
- Rate limiting detection and handling
- Support for both Meta Graph API and Kapso proxy
- Webhook signature verification utilities
- Extensive documentation and examples
- Test suite with VCR cassettes
- Ruby 2.7+ compatibility

### Features

#### Core Messaging
- Send text messages with URL preview support
- Send media messages (images, audio, video, documents, stickers)
- Send location and contact messages
- Send interactive button and list messages
- Send template messages with parameter substitution
- Message reactions (add/remove)
- Message read status and typing indicators

#### Media Management
- Upload media files with automatic MIME type detection
- Download media with authentication handling
- Get media metadata (size, type, SHA256)
- Delete media files
- Save media directly to files
- Support for different authentication strategies

#### Template Management
- List, create, update, and delete message templates
- Template builders for marketing, utility, and authentication templates
- Component validation and example handling
- Support for all template types (text, media, interactive)

#### Advanced Features (Kapso Proxy)
- Message history queries with filtering
- Conversation management and status updates
- Contact management with metadata and search
- Call history and management
- Analytics and reporting
- Data export/import capabilities

#### Error Handling
- Comprehensive error categorization (14+ categories)
- Intelligent retry recommendations
- Rate limiting detection with retry-after support
- Detailed error context and debugging information
- Custom error classes for different scenarios

#### Developer Experience
- Extensive documentation with code examples
- Debug logging with request/response tracing
- Configurable HTTP client with connection pooling
- Type-safe response objects
- Comprehensive test suite
- Ruby best practices and conventions

### Dependencies
- faraday (~> 2.0) - HTTP client
- faraday-multipart (~> 1.0) - Multipart form support
- mime-types (~> 3.0) - MIME type detection
- dry-validation (~> 1.10) - Input validation

### Development Dependencies
- rspec (~> 3.0) - Testing framework
- webmock (~> 3.18) - HTTP request mocking
- vcr (~> 6.0) - HTTP interaction recording
- rubocop (~> 1.50) - Code style checking
- simplecov (~> 0.22) - Code coverage
- yard (~> 0.9) - Documentation generation