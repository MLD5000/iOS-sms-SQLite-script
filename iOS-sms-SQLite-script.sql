-- SQLite script to get all messages from iOS sms.db
-- script is based on latest iOS version, may not be backwards compatible
-- Does not include all columns from all tables, but I picked what appear to be the most usefull
-- Author: Matt Danner, Monolith Forensics - 2022-04-14

SELECT
message.text, message.service, message.account, message.is_from_me, message.is_read, message.is_sent, message.cache_has_attachments,
message.date,
CASE LENGTH(message.date)
	WHEN 18 THEN strftime('%Y-%m-%dT%H:%M:%SZ',(message.date / 1000000000) + 978307200, 'unixepoch') 
	WHEN 9 THEN strftime('%Y-%m-%dT%H:%M:%SZ', message.date + 978307200, 'unixepoch') 
	ELSE NULL
	END AS date_iso,
message.date_read,
CASE LENGTH(message.date_read)
	WHEN 18 THEN strftime('%Y-%m-%dT%H:%M:%SZ',(message.date_read / 1000000000) + 978307200, 'unixepoch') 
	WHEN 9 THEN strftime('%Y-%m-%dT%H:%M:%SZ', message.date_read + 978307200, 'unixepoch') 
	ELSE NULL
	END AS date_read_iso,
message.date_delivered,
CASE LENGTH(message.date_delivered)
	WHEN 18 THEN strftime('%Y-%m-%dT%H:%M:%SZ',(message.date_delivered / 1000000000) + 978307200, 'unixepoch') 
	WHEN 9 THEN strftime('%Y-%m-%dT%H:%M:%SZ', message.date_delivered + 978307200, 'unixepoch') 
	ELSE NULL
	END AS date_delivered_iso,
chat_message_join.message_date,
CASE LENGTH(chat_message_join.message_date)
	WHEN 18 THEN strftime('%Y-%m-%dT%H:%M:%SZ',(chat_message_join.message_date / 1000000000) + 978307200, 'unixepoch') 
	WHEN 9 THEN strftime('%Y-%m-%dT%H:%M:%SZ', chat_message_join.message_date + 978307200, 'unixepoch') 
	ELSE NULL
	END AS message_date_iso,
attachments.attachment_data, attachments.attachment_count,
chat.service_name, chat.display_name AS chat_display_name, chat.last_read_message_timestamp AS chat_last_read_message_timestamp,
handles.participants, handles.participant_count
FROM message
LEFT JOIN (
	SELECT JSON_GROUP_ARRAY(
	JSON_OBJECT(
	'created_date', attachment.created_date, 
	'created_date_iso', 
	CASE LENGTH(attachment.created_date)
		WHEN 18 THEN strftime('%Y-%m-%dT%H:%M:%SZ',(attachment.created_date / 1000000000) + 978307200, 'unixepoch') 
		WHEN 9 THEN strftime('%Y-%m-%dT%H:%M:%SZ', attachment.created_date + 978307200, 'unixepoch') 
		ELSE NULL
		END,
	'start_date', attachment.start_date,
	'start_date_iso', 
	CASE LENGTH(attachment.start_date)
		WHEN 18 THEN strftime('%Y-%m-%dT%H:%M:%SZ',(attachment.start_date / 1000000000) + 978307200, 'unixepoch') 
		WHEN 9 THEN strftime('%Y-%m-%dT%H:%M:%SZ', attachment.start_date + 978307200, 'unixepoch') 
		ELSE NULL
		END,
	'filename', attachment.filename,
	'mime_type', attachment.mime_type, 
	'transfer_name', attachment.transfer_name, 
	'total_bytes', attachment.total_bytes
	)
	) AS attachment_data, message_attachment_join.message_id,
	COUNT(attachment.ROWID) AS attachment_count
	FROM attachment
	LEFT JOIN message_attachment_join
	ON message_attachment_join.attachment_id = attachment.ROWID
	GROUP BY message_attachment_join.message_id
) attachments
ON attachments.message_id = message.ROWID
LEFT JOIN chat_message_join
ON chat_message_join.message_id = message.ROWID
LEFT JOIN chat
ON chat.ROWID = chat_message_join.chat_id
LEFT JOIN (
	SELECT JSON_GROUP_ARRAY(handle.id) AS participants, handle.ROWID, chat_handle_join.chat_id, COUNT(handle.id) AS participant_count
	FROM handle
	LEFT JOIN chat_handle_join
	ON chat_handle_join.handle_id = handle.ROWID
	GROUP BY chat_handle_join.chat_id
) handles
ON handles.chat_id = chat.ROWID