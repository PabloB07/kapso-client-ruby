# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.2] - 2025-12-10

### Added Flows API

#### Flows Resource (`client.flows`)
- **Flow Management**:
  - `create()` - Create a new WhatsApp Flow
  - `update()` - Update Flow properties
  - `delete()` - Delete a Flow
  - `get()` - Retrieve Flow details
  - `list()` - List all Flows for a business account
  
- **Flow Lifecycle**:
  - `publish()` - Publish a Flow to production
  - `deprecate()` - Deprecate an existing Flow
  - `update_asset()` - Update Flow JSON definition with validation
  - `preview()` - Get Flow preview URL and expiration
  - `deploy()` - Idempotent deployment (create/update + publish)

- **Flow Webhooks & Server Utilities**:
  - `receive_flow_event()` - Decrypt incoming Flow webhook events
  - `respond_to_flow()` - Encrypt Flow responses for WhatsApp
  - `download_flow_media()` - Download media from Flow submissions
  - AES-128-GCM encryption/decryption with RSA key exchange
  - Automatic payload parsing and validation

#### Messages Enhancement
- **Flow Messages**:
  - `send_flow()` - Send interactive Flow messages
  - Support for Flow CTA buttons
  - Flow token generation for session tracking
  - Navigate to specific screens
  - Flow action payload support

#### New Types
- `FlowResponse` - Flow creation/update response
- `FlowData` - Detailed Flow information
- `FlowAssetResponse` - Asset update validation results
- `FlowPreviewResponse` - Preview URL and expiration
- `FlowEventData` - Decrypted Flow webhook events
- `FlowScreen` - Flow screen configuration

#### New Errors
- `FlowDecryptionError` - Flow webhook decryption failures
- `FlowEncryptionError` - Flow response encryption failures

#### Documentation
- Complete Flows API documentation in README
- Flow usage examples (`examples/flows_usage.rb`)
- Webhook handling guide
- Encryption/decryption examples

### Added Interactive Messages

#### Interactive CTA URL Messages
- **`send_interactive_cta_url()`** - Send Call-to-Action URL buttons
  - Support for text, image, video, and document headers
  - URL validation (HTTP/HTTPS)
  - Display text max 20 characters
  - Body text max 1024 characters
  - Optional footer text (max 60 characters)

#### Catalog Messages
- **`send_interactive_catalog_message()`** - Send product catalog messages
  - Thumbnail product selection via retailer ID
  - Body text validation (max 1024 characters)
  - Optional footer text (max 60 characters)

#### Enhanced Validations
- **Header validation** for interactive messages
  - Text header: max 60 characters
  - Media headers: require id or link
  - Type validation (text, image, video, document)
- **Parameter validation**:
  - CTA URL: display_text, url, body_text, footer_text
  - Catalog: body_text, thumbnail_product_retailer_id, footer_text
- **Comprehensive error messages** with current vs. max values

#### New Private Methods
- `validate_cta_url_params()` - CTA URL parameter validation
- `validate_catalog_message_params()` - Catalog message parameter validation
- `validate_interactive_header()` - Header type and content validation
- `validate_text_header()` - Text header specific validation
- `validate_media_header()` - Media header specific validation

#### Documentation
- Interactive Messages examples (`examples/interactive_messages.rb`)
- CTA URL usage with all header types
- Catalog message examples
- Validation examples and error handling
- Real-world use cases (e-commerce, events, support, restaurants)
- README updates with comprehensive examples

### Added Enhanced Features & Validations

#### Enhanced Interactive Button Messages
- **Media header support** for buttons (previously text-only)
  - Image headers: Display product images with buttons
  - Video headers: Show tutorial videos with feedback buttons
  - Document headers: Attach PDFs/docs with approval buttons
  - Text headers: Traditional text-only headers (existing)
- **Button validations**:
  - Maximum 3 buttons enforced
  - Minimum 1 button required
  - Header type validation (text, image, video, document)
  - Media header content validation (requires id or link)

#### Enhanced Interactive List Messages
- **Increased body text limit**: 1024 → 4096 characters
- **Row count validation**: Maximum 10 rows total across all sections
- **Header restriction**: Text headers only (no media headers for lists)
- **Improved validations**:
  - Total row count across all sections enforced
  - At least 1 row required
  - Header type validation (text only)
  - Body text length validation with detailed error messages

#### Updated Validations
- **Footer handling**: Support for both string and hash formats
- **Enhanced error messages**: Show current vs. maximum values
- **Consistent validation**: All interactive message types use shared validators

#### Documentation
- Enhanced Interactive Messages examples (`examples/enhanced_interactive.rb`)
- Button header examples (text, image, video, document)
- List validation examples (4096 chars, 10 rows, text  header)
- Real-world use cases (product selection, tutorials, document approvals)
- README updates with detailed examples and validation notes

### Added Advanced Messaging Features

#### Voice Notes Support
- **Audio voice notes** via `send_audio(voice: true)`
  - Voice flag for voice note format (recommended: OGG/OPUS)
  - Regular audio messages when `voice: false` (default)
  - Perfect for personal messages and support responses

#### Group Messaging Support
- **`recipient_type` parameter** added to all send methods
  - `'individual'` - Send to individual users (default)
  - `'group'` - Send to WhatsApp groups
  - Group ID format: `XXXXXXXXX@g.us`
- **Supported for all message types**:
  - Text, images, videos, documents, audio, stickers
  - All interactive messages (buttons, lists, CTA URL, etc.)
  - Templates, reactions, contacts, location
- **Validation**: Enforces valid recipient types ('individual' or 'group')

#### Location Request Action
- **`send_interactive_location_request()`** - Request user location
  - Interactive message asking users to share location
  - Supports headers (text, image, video, document)
  - Optional footer text
  - Perfect for delivery services, meetups, directions
  - Action: `{ name: 'send_location' }`

#### Updated Core Methods
- **`build_base_payload()`** - Enhanced with `recipient_type` support
- **`send_text()`** - Added `recipient_type` parameter
- **`send_image()`** - Added `recipient_type` parameter
- **`send_video()`** - Added `recipient_type` parameter
- **`send_audio()`** - Added `voice` and `recipient_type` parameters

#### Documentation
- Advanced Messaging examples (`examples/advanced_messaging.rb`)
- Voice note usage (voice flag, formats)
- Group messaging examples (text, images, videos)
- Location request examples (with/without headers)
- Real-world use cases (support, teams, delivery, education, real estate, community)
- README updates with all new features

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
