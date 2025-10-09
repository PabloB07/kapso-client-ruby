# frozen_string_literal: true

require 'whatsapp_cloud_api'

puts "=== Media Management Examples ==="

# Initialize client
client = KapsoClientRuby::Client.new(
  access_token: ENV['WHATSAPP_ACCESS_TOKEN'],
  debug: true # Enable debug logging
)

# Example 1: Upload Media File
puts "\n--- Upload Media File ---"

begin
  # Upload an image file
  upload_response = client.media.upload(
    phone_number_id: ENV['PHONE_NUMBER_ID'],
    type: 'image',
    file: 'path/to/your/image.jpg', # Replace with actual file path
    filename: 'my_image.jpg'
  )
  
  media_id = upload_response.id
  puts "File uploaded successfully!"
  puts "Media ID: #{media_id}"
  
  # Get media metadata
  metadata = client.media.get(media_id: media_id)
  puts "\nMedia Metadata:"
  puts "URL: #{metadata.url}"
  puts "MIME Type: #{metadata.mime_type}"
  puts "File Size: #{metadata.file_size} bytes"
  puts "SHA256: #{metadata.sha256}"
  
  # Send the uploaded media
  message_response = client.messages.send_image(
    phone_number_id: ENV['PHONE_NUMBER_ID'],
    to: '+1234567890',
    image: { id: media_id, caption: 'Uploaded via Ruby SDK!' }
  )
  
  puts "\nMessage sent with uploaded media: #{message_response.messages.first.id}"

rescue KapsoClientRuby::Errors::GraphApiError => e
  puts "Upload error: #{e.message}"
  puts "Category: #{e.category}"
  
  case e.category
  when :media
    puts "Media-specific error - check file format, size, or type"
  when :parameter
    puts "Parameter error - check phone_number_id and file path"
  end
end

# Example 2: Upload Different Media Types
puts "\n--- Upload Different Media Types ---"

media_examples = [
  { type: 'image', file: 'examples/sample_image.jpg', message_method: :send_image },
  { type: 'audio', file: 'examples/sample_audio.mp3', message_method: :send_audio },
  { type: 'video', file: 'examples/sample_video.mp4', message_method: :send_video },
  { type: 'document', file: 'examples/sample_document.pdf', message_method: :send_document }
]

media_examples.each do |example|
  begin
    next unless File.exist?(example[:file]) # Skip if file doesn't exist
    
    puts "\nUploading #{example[:type]}: #{example[:file]}"
    
    upload_response = client.media.upload(
      phone_number_id: ENV['PHONE_NUMBER_ID'],
      type: example[:type],
      file: example[:file]
    )
    
    puts "Uploaded #{example[:type]} - Media ID: #{upload_response.id}"
    
    # Send message with the uploaded media
    case example[:message_method]
    when :send_image
      client.messages.send_image(
        phone_number_id: ENV['PHONE_NUMBER_ID'],
        to: '+1234567890',
        image: { id: upload_response.id, caption: "#{example[:type].capitalize} via Ruby SDK" }
      )
    when :send_audio
      client.messages.send_audio(
        phone_number_id: ENV['PHONE_NUMBER_ID'],
        to: '+1234567890',
        audio: { id: upload_response.id }
      )
    when :send_video
      client.messages.send_video(
        phone_number_id: ENV['PHONE_NUMBER_ID'],
        to: '+1234567890',
        video: { id: upload_response.id, caption: "Video via Ruby SDK" }
      )
    when :send_document
      client.messages.send_document(
        phone_number_id: ENV['PHONE_NUMBER_ID'],
        to: '+1234567890',
        document: { 
          id: upload_response.id, 
          caption: "Document via Ruby SDK",
          filename: File.basename(example[:file])
        }
      )
    end
    
    puts "Message sent successfully!"

  rescue KapsoClientRuby::Errors::GraphApiError => e
    puts "Error with #{example[:type]}: #{e.message}"
  rescue StandardError => e
    puts "File error with #{example[:file]}: #{e.message}"
  end
end

# Example 3: Download Media
puts "\n--- Download Media ---"

begin
  # First, get a media ID (you would normally get this from webhook or previous upload)
  sample_media_id = "your_media_id_here" # Replace with actual media ID
  
  # Download media content
  puts "Downloading media: #{sample_media_id}"
  
  # Method 1: Download to memory
  content = client.media.download(
    media_id: sample_media_id,
    phone_number_id: ENV['PHONE_NUMBER_ID'],
    as: :binary
  )
  
  puts "Downloaded #{content.length} bytes"
  
  # Method 2: Save directly to file
  saved_path = client.media.save_to_file(
    media_id: sample_media_id,
    filepath: "downloaded_media_#{sample_media_id}.jpg",
    phone_number_id: ENV['PHONE_NUMBER_ID']
  )
  
  puts "Media saved to: #{saved_path}"
  
  # Method 3: Get as base64
  base64_content = client.media.download(
    media_id: sample_media_id,
    phone_number_id: ENV['PHONE_NUMBER_ID'],
    as: :base64
  )
  
  puts "Base64 content (first 100 chars): #{base64_content[0..100]}..."

rescue KapsoClientRuby::Errors::GraphApiError => e
  puts "Download error: #{e.message}"
  
  if e.http_status == 404
    puts "Media not found - it may have been deleted or expired"
  elsif e.http_status == 403
    puts "Access denied - check your permissions"
  end
end

# Example 4: Media Management with Kapso Proxy
puts "\n--- Media Management with Kapso Proxy ---"

begin
  # Initialize Kapso client
  kapso_client = KapsoClientRuby::Client.new(
    kapso_api_key: ENV['KAPSO_API_KEY'],
    base_url: 'https://app.kapso.ai/api/meta'
  )
  
  # With Kapso proxy, phone_number_id is required for media operations
  media_id = "sample_media_id"
  
  # Get media info (includes enhanced metadata from Kapso)
  info = kapso_client.media.info(
    media_id: media_id,
    phone_number_id: ENV['PHONE_NUMBER_ID']
  )
  
  puts "Media Info:"
  puts "ID: #{info[:id]}"
  puts "MIME Type: #{info[:mime_type]}"
  puts "Size: #{info[:file_size]} bytes"
  puts "URL: #{info[:url]}"

rescue KapsoClientRuby::Errors::GraphApiError => e
  puts "Kapso media error: #{e.message}"
end

# Example 5: Error Handling and Retry Logic
puts "\n--- Error Handling and Retry Logic ---"

def upload_with_retry(client, phone_number_id, file_path, max_retries = 3)
  retries = 0
  
  begin
    client.media.upload(
      phone_number_id: phone_number_id,
      type: 'image',
      file: file_path
    )
  rescue KapsoClientRuby::Errors::GraphApiError => e
    retries += 1
    
    case e.retry_hint[:action]
    when :retry
      if retries <= max_retries
        puts "Retrying upload (attempt #{retries}/#{max_retries})..."
        sleep(1 * retries) # Exponential backoff
        retry
      else
        puts "Max retries exceeded"
        raise
      end
    when :retry_after
      if retries <= max_retries && e.retry_hint[:retry_after_ms]
        delay_seconds = e.retry_hint[:retry_after_ms] / 1000.0
        puts "Rate limited. Waiting #{delay_seconds} seconds..."
        sleep(delay_seconds)
        retry
      else
        raise
      end
    when :do_not_retry
      puts "Permanent error - do not retry: #{e.message}"
      raise
    else
      puts "Unknown error - manual intervention needed: #{e.message}"
      raise
    end
  end
end

begin
  response = upload_with_retry(
    client,
    ENV['PHONE_NUMBER_ID'],
    'examples/sample_image.jpg'
  )
  puts "Upload successful with retry logic: #{response.id}"
rescue => e
  puts "Final upload error: #{e.message}"
end

puts "\n=== Media Management Examples Completed ==="