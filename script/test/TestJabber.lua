--[[
Author: LiXizhi
Date: 2008-11-29
Desc: testing NPL's networking functionalities such as Jabber 
-----------------------------------------------
NPL.load("(gl)script/test/TestJabber.lua");
-----------------------------------------------
]]

--[[
	/** Jabber events that a JC client can bind to. such as jc:AddEventListener("JE_OnMessage", "commonlib.echo(msg)");
	* in the event handler, one can access data via the msg variable. 
	*/
	enum JabberEvents{
		JE_NONE,

		JE_OnPresence = 0,//We received a presence packet. 
		JE_OnError,
		JE_OnRegistered,//After calling Register(), the registration succeeded or failed.
		JE_OnRegisterInfo,//after calling Register, information about the user is required.  Fill in the given IQ with the requested information.
		JE_OnIQ,//We received an IQ packet.
		/** Authentication failed.  The connection is not terminated if there is an auth error and there is at least one event handler for this event.
		* msg = {jckey, reason=number:AuthenticationError} 
		*/
		JE_OnAuthError,
		JE_OnLoginRequired,//AutoLogin is false, and it's time to log in.
		/** The connection is connected, but no stream:stream has been sent, yet.
		* msg = {jckey} 	*/
		JE_OnConnect,
		/** The connection is complete, and the user is authenticated.
		* msg = {jckey} */
		JE_OnAuthenticate, // 
		/** The connection is disconnected or auth failed.
		msg = {jckey, errorcode=number:ConnectionError, streamError=:number(StreamError)} */
		JE_OnDisconnect,
		/** msg = {jckey, state=number, issuer=string, peer=string,protocol=string,mac=string,cipher=string,compression=string,from =string,to=string} */
		JE_OnTLSConnect,

		/** roster arrived. array of jid roster tables. each jid may belong to 0 or multiple groups and resources. 
		msg = {jckey, 
			{jid=string:jid, name=string,subscription=int:SubscriptionEnum, groups={string, string, ...}, resources={string, string, ...},},
			{jid=string:jid, name=string,subscription=int:SubscriptionEnum, groups={string, string, ...}, resources={string, string, ...},},
			{jid=string:jid, name=string,subscription=int:SubscriptionEnum, groups={string, string, ...}, resources={string, string, ...},},
			...
		}
		*/
		JE_OnRoster,
		JE_OnRosterBegin, // Fired when a roster result starts, before any OnRosterItem events fire.
		JE_OnRosterItem, //event for new roster items. A roster may belong to multiple groups
		JE_OnRosterEnd, //Fired when a roster result is completed being processed.
		JE_OnRosterError,
		/** a roster item's presence arrived. 
		msg = {jckey, jid=string:jid, resource=string, presence=int:Presence}
		*/
		JE_OnRosterPresence,
		/** the user itself's presence arrived.
		msg = {jckey, jid=string:jid, resource=string, presence=int:Presence}
		*/
		JE_OnSelfPresence,

		/** We received a message packet.
		* msg = {jckey, from=string:jid,  subtype=int:StanzaSubType, subject=string, body=string}
		*/
		JE_OnMessage,
		JE_OnStanzaMessageChat,
		JE_OnStanzaMessageGroupChat,
		JE_OnStanzaMessageHeadline,
		JE_OnStanzaMessageNormal,
		/** msg = {jckey, from=string:jid, state=number:ChatStateType} */
		JE_OnChatState,
		/** msg = {jckey, from=string:jid, event=number:MessageEventType} */
		JE_OnMessageEvent,
		
		/** msg = {jckey, error=int:ResourceBindError} */
		JE_OnResourceBindError,
		/** msg = {jckey, error=int:SessionCreateError} */
		JE_OnSessionCreateError,

		/** msg = {jckey, from=string:jid} */
		JE_OnItemSubscribed,
		/** msg = {jckey, from=string:jid} */
		JE_OnItemAdded,
		/** msg = {jckey, from=string:jid} */
		JE_OnItemUnsubscribed,
		/** msg = {jckey, from=string:jid} */
		JE_OnItemRemoved,
		/** msg = {jckey, from=string:jid} */
		JE_OnItemUpdated,
		
		/** msg={jckey, jid=string:jid}*/
		JE_OnSubscriptionRequest,
		/** msg={jckey, jid=string:jid,msg=string}*/
		JE_OnUnsubscriptionRequest,
		/** msg={jckey, jid=string:jid}*/
		JE_OnNonrosterPresence,

		JE_LAST,
		JE_UNKNOWN=0xffff,
	};

  /**
   * This describes connection error conditions.
   */
  enum ConnectionError
  {
    ConnNoError,                    /**< Not really an error. Everything went just fine. */
    ConnStreamError,                /**< A stream error occured. The stream has been closed.
                                     * Use ClientBase::streamError() to find the reason. */
    ConnStreamVersionError,         /**< The incoming stream's version is not supported */
    ConnStreamClosed,               /**< The stream has been closed (by the server). */
    ConnProxyAuthRequired,          /**< The HTTP/SOCKS5 proxy requires authentication.
                                     * @since 0.9 */
    ConnProxyAuthFailed,            /**< HTTP/SOCKS5 proxy authentication failed.
                                     * @since 0.9 */
    ConnProxyNoSupportedAuth,       /**< The HTTP/SOCKS5 proxy requires an unsupported auth mechanism.
                                     * @since 0.9 */
    ConnIoError,                    /**< An I/O error occured. */
    ConnParseError,                 /**< An XML parse error occurred. */
    ConnConnectionRefused,          /**< The connection was refused by the server (on the socket level).
                                     * @since 0.9 */
    ConnDnsError,                   /**< Resolving the server's hostname failed.
                                     * @since 0.9 */
    ConnOutOfMemory,                /**< Out of memory. Uhoh. */
    ConnNoSupportedAuth,            /**< The auth mechanisms the server offers are not supported
                                     * or the server offered no auth mechanisms at all. */
    ConnTlsFailed,                  /**< The server's certificate could not be verified or the TLS
                                     * handshake did not complete successfully. */
    ConnTlsNotAvailable,            /**< The server didn't offer TLS while it was set to be required
                                     * or TLS was not compiled in.
                                     * @since 0.9.4 */
    ConnCompressionFailed,          /**< Negotiating/initializing compression failed.
                                     * @since 0.9 */
    ConnAuthenticationFailed,       /**< Authentication failed. username/password wrong or account does
                                     * not exist. Use ClientBase::authError() to find the reason. */
    ConnUserDisconnected,           /**< The user (or higher-level protocol) requested a disconnect. */
    ConnNotConnected                /**< There is no active connection. */
  };

  /**
   * ClientBase's policy regarding TLS usage. Use with ClientBase::setTls().
   */
  enum TLSPolicy
  {
    TLSDisabled,                    /**< Don't use TLS. */
    TLSOptional,                    /**< Use TLS if compiled in and offered by the server. */
    TLSRequired                     /**< Don't attempt to log in if the server didn't offer TLS
                                     * or if TLS was not compiled in. Disconnect error will be
                                     * ConnTlsNotAvailable. */
  };

  /**
   * Supported Stream Features.
   */
  enum StreamFeature
  {
    StreamFeatureBind             =    1, /**< The server supports resource binding. */
    StreamFeatureSession          =    2, /**< The server supports sessions. */
    StreamFeatureStartTls         =    8, /**< The server supports &lt;starttls&gt;. */
    StreamFeatureIqRegister       =   16, /**< The server supports XEP-0077 (In-Band
                                           * Registration). */
    StreamFeatureIqAuth           =   32, /**< The server supports XEP-0078 (Non-SASL
                                           * Authentication). */
    StreamFeatureCompressZlib     =   64, /**< The server supports XEP-0138 (Stream
                                           * Compression) (Zlib). */
    StreamFeatureCompressDclz     =  128  /**< The server supports XEP-0138 (Stream
                                           * Compression) (LZW/DCLZ). */
    // SASLMechanism below must be adjusted accordingly.
  };

  /**
   * Supported SASL mechanisms.
   */
  // must be adjusted with changes to StreamFeature enum above
  enum SaslMechanism
  {
    SaslMechNone           =     0, /**< Invalid SASL Mechanism. */
    SaslMechDigestMd5      =   256, /**< SASL Digest-MD5 according to RFC 2831. */
    SaslMechPlain          =   512, /**< SASL PLAIN according to RFC 2595 Section 6. */
    SaslMechAnonymous      =  1024, /**< SASL ANONYMOUS according to draft-ietf-sasl-anon-05.txt/
                                     * RFC 2245 Section 6. */
    SaslMechExternal       =  2048, /**< SASL EXTERNAL according to RFC 2222 Section 7.4. */
    SaslMechGssapi         =  4096, /**< SASL GSSAPI (Win32 only). */
    SaslMechAll            = 65535  /**< Includes all supported SASL mechanisms. */
  };

  /**
   * This decribes stream error conditions as defined in RFC 3920 Sec. 4.7.3.
   */
  enum StreamError
  {
    StreamErrorUndefined,           /**< An undefined/unknown error occured. Also used if a diconnect was
                                     * user-initiated. Also set before and during a established connection
                                     * (where obviously no error occured). */
    StreamErrorBadFormat,           /**< The entity has sent XML that cannot be processed;
                                     * this error MAY be used instead of the more specific XML-related
                                     * errors, such as &lt;bad-namespace-prefix/&gt;, &lt;invalid-xml/&gt;,
                                     * &lt;restricted-xml/&gt;, &lt;unsupported-encoding/&gt;, and
                                     * &lt;xml-not-well-formed/&gt;, although the more specific errors are
                                     * preferred. */
    StreamErrorBadNamespacePrefix,  /**< The entity has sent a namespace prefix that is unsupported, or has
                                     * sent no namespace prefix on an element that requires such a prefix
                                     * (see XML Namespace Names and Prefixes (Section 11.2)). */
    StreamErrorConflict,            /**< The server is closing the active stream for this entity because a
                                     * new stream has been initiated that conflicts with the existing
                                     * stream. */
    StreamErrorConnectionTimeout,   /**< The entity has not generated any traffic over the stream for some
                                     * period of time (configurable according to a local service policy).*/
    StreamErrorHostGone,            /**< the value of the 'to' attribute provided by the initiating entity
                                     * in the stream header corresponds to a hostname that is no longer
                                     * hosted by the server.*/
    StreamErrorHostUnknown,         /**< The value of the 'to' attribute provided by the initiating entity
                                     * in the stream header does not correspond to a hostname that is hosted
                                     * by the server. */
    StreamErrorImproperAddressing,  /**< A stanza sent between two servers lacks a 'to' or 'from' attribute
                                     * (or the attribute has no value). */
    StreamErrorInternalServerError, /**< the server has experienced a misconfiguration or an
                                     * otherwise-undefined internal error that prevents it from servicing the
                                     * stream. */
    StreamErrorInvalidFrom,         /**< The JID or hostname provided in a 'from' address does not match an
                                     * authorized JID or validated domain negotiated between servers via SASL
                                     * or dialback, or between a client and a server via authentication and
                                     * resource binding.*/
    StreamErrorInvalidId,           /**< The stream ID or dialback ID is invalid or does not match an ID
                                     * previously provided. */
    StreamErrorInvalidNamespace,    /**< The streams namespace name is something other than
                                     * "http://etherx.jabber.org/streams" or the dialback namespace name is
                                     * something other than "jabber:server:dialback" (see XML Namespace Names
                                     * and Prefixes (Section 11.2)). */
    StreamErrorInvalidXml,          /**< The entity has sent invalid XML over the stream to a server that
                                     * performs validation (see Validation (Section 11.3)). */
    StreamErrorNotAuthorized,       /**< The entity has attempted to send data before the stream has been
                                     * authenticated, or otherwise is not authorized to perform an action
                                     * related to stream negotiation; the receiving entity MUST NOT process
                                     * the offending stanza before sending the stream error. */
    StreamErrorPolicyViolation,     /**< The entity has violated some local service policy; the server MAY
                                     * choose to specify the policy in the &lt;text/&gt;  element or an
                                     * application-specific condition element. */
    StreamErrorRemoteConnectionFailed,/**< The server is unable to properly connect to a remote entity that is
                                     * required for authentication or authorization. */
    StreamErrorResourceConstraint,  /**< the server lacks the system resources necessary to service the
                                     * stream. */
    StreamErrorRestrictedXml,       /**< The entity has attempted to send restricted XML features such as a
                                     * comment, processing instruction, DTD, entity reference, or unescaped
                                     * character (see Restrictions (Section 11.1)). */
    StreamErrorSeeOtherHost,        /**< The server will not provide service to the initiating entity but is
                                     * redirecting traffic to another host; the server SHOULD specify the
                                     * alternate hostname or IP address (which MUST be a valid domain
                                     * identifier) as the XML character data of the &lt;see-other-host/&gt;
                                     * element. */
    StreamErrorSystemShutdown,      /**< The server is being shut down and all active streams are being
                                     * closed. */
    StreamErrorUndefinedCondition,  /**< The error condition is not one of those defined by the other
                                     * conditions in this list; this error condition SHOULD be used only in
                                     * conjunction with an application-specific condition. */
    StreamErrorUnsupportedEncoding, /**< The initiating entity has encoded the stream in an encoding that is
                                     * not supported by the server (see Character Encoding (Section 11.5)).
                                     */
    StreamErrorUnsupportedStanzaType,/**< The initiating entity has sent a first-level child of the stream
                                     * that is not supported by the server. */
    StreamErrorUnsupportedVersion,  /**< The value of the 'version' attribute provided by the initiating
                                     * entity in the stream header specifies a version of XMPP that is not
                                     * supported by the server; the server MAY specify the version(s) it
                                     * supports in the &lt;text/&gt; element. */
    StreamErrorXmlNotWellFormed     /**< The initiating entity has sent XML that is not well-formed as
                                     * defined by [XML]. */
  };

  /**
   * Describes the possible stanza types.
   */
  enum StanzaType
  {
    StanzaUndefined,                /**< Undefined. */
    StanzaIq,                       /**< An Info/Query stanza. */
    StanzaMessage,                  /**< A message stanza. */
    StanzaS10n,                     /**< A presence/subscription stanza. */
    StanzaPresence                  /**< A presence stanza. */
  };

  /**
   * Describes the possible stanza-sub-types.
   */
  enum StanzaSubType
  {
    StanzaSubUndefined        =  0, /**< Undefined. */
    StanzaIqGet               =  1, /**< The stanza is a request for information or requirements. */
    StanzaIqSet               =  2, /**<
                                     * The stanza provides required data, sets new values, or
                                     * replaces existing values.
                                     */
    StanzaIqResult            =  4, /**< The stanza is a response to a successful get or set request. */
    StanzaIqError             =  8, /**<
                                     * An error has occurred regarding processing or
                                     * delivery of a previously-sent get or set (see Stanza Errors
                                     * (Section 9.3)).
                                     */
    StanzaPresenceUnavailable = 16,      /**<
                                     * Signals that the entity is no longer available for
                                     * communication.
                                     */
    StanzaPresenceAvailable =   32, /**<
                                     * Signals to the server that the sender is online and available
                                     * for communication.
                                     */
    StanzaPresenceProbe    =    64, /**<
                                     * A request for an entity's current presence; SHOULD be
                                     * generated only by a server on behalf of a user.
                                     */
    StanzaPresenceError    =   128, /**<
                                     * An error has occurred regarding processing or delivery of
                                     * a previously-sent presence stanza.
                                     */
    StanzaS10nSubscribe    =   256, /**<
                                     * The sender wishes to subscribe to the recipient's
                                     * presence.
                                     */
    StanzaS10nSubscribed   =   512, /**<
                                     * The sender has allowed the recipient to receive
                                     * their presence.
                                     */
    StanzaS10nUnsubscribe  =  1024, /**<
                                     * The sender is unsubscribing from another entity's
                                     * presence.
                                     */
    StanzaS10nUnsubscribed =  2048, /**<
                                     * The subscription request has been denied or a
                                     * previously-granted subscription has been cancelled.
                                     */
    StanzaMessageChat      =  4096, /**<
                                     * The message is sent in the context of a one-to-one chat
                                     * conversation. A compliant client SHOULD present the message in an
                                     * interface enabling one-to-one chat between the two parties,
                                     * including an appropriate conversation history.
                                     */
    StanzaMessageError     =  8192, /**<
                                     * An error has occurred related to a previous message sent
                                     * by the sender (for details regarding stanza error syntax, refer to
                                     * [XMPP-CORE]). A compliant client SHOULD present an appropriate
                                     * interface informing the sender of the nature of the error.
                                     */
    StanzaMessageGroupchat = 16384, /**<
                                     * The message is sent in the context of a multi-user
                                     * chat environment (similar to that of [IRC]). A compliant client
                                     * SHOULD present the message in an interface enabling many-to-many
                                     * chat between the parties, including a roster of parties in the
                                     * chatroom and an appropriate conversation history.
                                     */
    StanzaMessageHeadline  = 32768, /**<
                                     * The message is probably generated by an automated
                                     * service that delivers or broadcasts content (news, sports, market
                                     * information, RSS feeds, etc.). No reply to the message is
                                     * expected, and a compliant client SHOULD present the message in an
                                     * interface that appropriately differentiates the message from
                                     * standalone messages, chat sessions, or groupchat sessions (e.g.,
                                     * by not providing the recipient with the ability to reply).
                                     */
    StanzaMessageNormal    = 65536  /**<
                                     * The message is a single message that is sent outside the
                                     * context of a one-to-one conversation or groupchat, and to which it
                                     * is expected that the recipient will reply. A compliant client
                                     * SHOULD present the message in an interface enabling the recipient
                                     * to reply, but without a conversation history.
                                     */
  };

  /**
   * Describes types of stanza errors.
   */
  enum StanzaErrorType
  {
    StanzaErrorTypeUndefined,       /**< No error. */
    StanzaErrorTypeCancel,          /**< Do not retry (the error is unrecoverable). */
    StanzaErrorTypeContinue,        /**< Proceed (the condition was only a warning). */
    StanzaErrorTypeModify,          /**< Retry after changing the data sent. */
    StanzaErrorTypeAuth,            /**< Retry after providing credentials. */
    StanzaErrorTypeWait             /**< Retry after waiting (the error is temporary). */
  };

  /**
   * Describes the defined stanza error conditions of RFC 3920.
   * Used by, eg., Stanza::error().
   */
  enum StanzaError
  {
    StanzaErrorUndefined = 0,       /**< No stanza error occured. */
    StanzaErrorBadRequest,          /**< The sender has sent XML that is malformed or that cannot be
                                     * processed (e.g., an IQ stanza that includes an unrecognized value
                                     * of the 'type' attribute); the associated error type SHOULD be
                                     * "modify". */
    StanzaErrorConflict,            /**< Access cannot be granted because an existing resource or session
                                     * exists with the same name or address; the associated error type
                                     * SHOULD be "cancel". */
    StanzaErrorFeatureNotImplemented,/**< The feature requested is not implemented by the recipient or server
                                     * and therefore cannot be processed; the associated error type SHOULD be
                                     * "cancel". */
    StanzaErrorForbidden,           /**< The requesting entity does not possess the required permissions to
                                     * perform the action; the associated error type SHOULD be "auth". */
    StanzaErrorGone,                /**< The recipient or server can no longer be contacted at this address
                                     * (the error stanza MAY contain a new address in the XML character data
                                     * of the &lt;gone/&gt; element); the associated error type SHOULD be
                                     * "modify". */
    StanzaErrorInternalServerError, /**< The server could not process the stanza because of a
                                     * misconfiguration or an otherwise-undefined internal server error; the
                                     * associated error type SHOULD be "wait". */
    StanzaErrorItemNotFound,        /**< The addressed JID or item requested cannot be found; the associated
                                     * error type SHOULD be "cancel". */
    StanzaErrorJidMalformed,        /**< The sending entity has provided or communicated an XMPP address
                                     * (e.g., a value of the 'to' attribute) or aspect thereof (e.g., a
                                     * resource identifier) that does not adhere to the syntax defined in
                                     * Addressing Scheme (Section 3); the associated error type SHOULD be
                                     * "modify". */
    StanzaErrorNotAcceptable,       /**< The recipient or server understands the request but is refusing to
                                     * process it because it does not meet criteria defined by the recipient
                                     * or server (e.g., a local policy regarding acceptable words in
                                     * messages); the associated error type SHOULD be "modify". */
    StanzaErrorNotAllowed,          /**< The recipient or server does not allow any entity to perform the
                                     * action; the associated error type SHOULD be "cancel". */
    StanzaErrorNotAuthorized,       /**< The sender must provide proper credentials before being allowed to
                                     * perform the action, or has provided improper credentials; the
                                     * associated error type SHOULD be "auth". */
    StanzaErrorPaymentRequired,     /**< The requesting entity is not authorized to access the requested
                                     * service because payment is required; the associated error type SHOULD
                                     * be "auth". */
    StanzaErrorRecipientUnavailable,/**< The intended recipient is temporarily unavailable; the associated
                                     * error type SHOULD be "wait" (note: an application MUST NOT return this
                                     * error if doing so would provide information about the intended
                                     * recipient's network availability to an entity that is not authorized
                                     * to know such information). */
    StanzaErrorRedirect,            /**< The recipient or server is redirecting requests for this information
                                     * to another entity, usually temporarily (the error stanza SHOULD
                                     * contain the alternate address, which MUST be a valid JID, in the XML
                                     * character data of the &lt;redirect/&gt; element); the associated
                                     * error type SHOULD be "modify". */
    StanzaErrorRegistrationRequired,/**< The requesting entity is not authorized to access the requested
                                     * service because registration is required; the associated error type
                                     * SHOULD be "auth". */
    StanzaErrorRemoteServerNotFound,/**< A remote server or service specified as part or all of the JID of
                                     * the intended recipient does not exist; the associated error type
                                     * SHOULD be "cancel". */
    StanzaErrorRemoteServerTimeout, /**< A remote server or service specified as part or all of the JID of
                                     * the intended recipient (or required to fulfill a request) could not be
                                     * contacted within a reasonable amount of time; the associated error
                                     * type SHOULD be "wait". */
    StanzaErrorResourceConstraint,  /**< The server or recipient lacks the system resources necessary to
                                     * service the request; the associated error type SHOULD be "wait". */
    StanzaErrorServiceUnavailable,  /**< The server or recipient does not currently provide the requested
                                     * service; the associated error type SHOULD be "cancel". */
    StanzaErrorSubscribtionRequired,/**< The requesting entity is not authorized to access the requested
                                     * service because a subscription is required; the associated error type
                                     * SHOULD be "auth". */
    StanzaErrorUndefinedCondition,  /**< The error condition is not one of those defined by the other
                                     * conditions in this list; any error type may be associated with this
                                     * condition, and it SHOULD be used only in conjunction with an
                                     * application-specific condition. */
    StanzaErrorUnexpectedRequest    /**< The recipient or server understood the request but was not expecting
                                     * it at this time (e.g., the request was out of order); the associated
                                     * error type SHOULD be "wait". */
  };

  /**
   * Describes the possible 'available presence' types.
   */
   --NOTE 2009/11/19: change Presence to PresenceType 0.97 -> 1.0
  enum PresenceType
  {
	----------- OLD -----------
    PresenceUnknown,                /**< Unknown status. */
    PresenceAvailable,              /**< The entity or resource is online and available. */
    PresenceChat,                   /**< The entity or resource is actively interested in chatting. */
    PresenceAway,                   /**< The entity or resource is temporarily away. */
    PresenceDnd,                    /**< The entity or resource is busy (dnd = "Do Not Disturb"). */
    PresenceXa,                     /**< The entity or resource is away for an extended period (xa =
                                     * "eXtended Away"). */
    PresenceUnavailable             /**< The entity or resource is offline. */
	---------------------------
    
	----------- NEW -----------
        Available,                  /**< The entity is online. */
        Chat,                       /**< The entity is 'available for chat'. */
        Away,                       /**< The entity is away. */
        DND,                        /**< The entity is DND (Do Not Disturb). */
        XA,                         /**< The entity is XA (eXtended Away). */
        Unavailable,                /**< The entity is offline. */
        Probe,                      /**< This is a presence probe. */
        Error,               
	---------------------------
  };
  
  /**
   * Describes the verification results of a certificate.
   */
  enum CertStatus
  {
    CertOk               =  0,      /**< The certificate is valid and trusted. */
    CertInvalid          =  1,      /**< The certificate is not trusted. */
    CertSignerUnknown    =  2,      /**< The certificate hasn't got a known issuer. */
    CertRevoked          =  4,      /**< The certificate has been revoked. */
    CertExpired          =  8,      /**< The certificate has expired. */
    CertNotActive        = 16,      /**< The certifiacte is not yet active. */
    CertWrongPeer        = 32,      /**< The certificate has not been issued for the
                                     * peer we're connected to. */
    CertSignerNotCa      = 64       /**< The signer is not a CA. */
  };

  /**
   * Describes the certificate presented by the peer.
   */
  struct CertInfo
  {
    int status;                     /**< Bitwise or'ed CertStatus or CertOK. */
    bool chain;                     /**< Determines whether the cert chain verified ok. */
    std::string issuer;             /**< The name of the issuing entity.*/
    std::string server;             /**< The server the certificate has been issued for. */
    int date_from;                  /**< The date from which onwards the certificate is valid
                                     * (in UTC, not set when using OpenSSL). */
    int date_to;                    /**< The date up to which the certificate is valid
                                     * (in UTC, not set when using OpenSSL). */
    std::string protocol;           /**< The encryption protocol used for the connection. */
    std::string cipher;             /**< The cipher used for the connection. */
    std::string mac;                /**< The MAC used for the connection. */
    std::string compression;        /**< The compression used for the connection. */
  };

  /**
   * Describes the defined SASL error conditions.
   */
  enum AuthenticationError
  {
    AuthErrorUndefined,             /**< No error occurred, or error condition is unknown. */
    SaslAborted,                    /**< The receiving entity acknowledges an &lt;abort/&gt; element sent
                                     * by the initiating entity; sent in reply to the &lt;abort/&gt;
                                     * element. */
    SaslIncorrectEncoding,          /**< The data provided by the initiating entity could not be processed
                                     * because the [BASE64] encoding is incorrect (e.g., because the encoding
                                     * does not adhere to the definition in Section 3 of [BASE64]); sent in
                                     * reply to a &lt;response/&gt; element or an &lt;auth/&gt; element with
                                     * initial response data. */
    SaslInvalidAuthzid,             /**< The authzid provided by the initiating entity is invalid, either
                                     * because it is incorrectly formatted or because the initiating entity
                                     * does not have permissions to authorize that ID; sent in reply to a
                                     * &lt;response/&gt; element or an &lt;auth/&gt; element with initial
                                     * response data.*/
    SaslInvalidMechanism,           /**< The initiating entity did not provide a mechanism or requested a
                                     * mechanism that is not supported by the receiving entity; sent in reply
                                     * to an &lt;auth/&gt; element. */
    SaslMechanismTooWeak,           /**< The mechanism requested by the initiating entity is weaker than
                                     * server policy permits for that initiating entity; sent in reply to a
                                     * &lt;response/&gt; element or an &lt;auth/&gt; element with initial
                                     * response data. */
    SaslNotAuthorized,              /**< The authentication failed because the initiating entity did not
                                     * provide valid credentials (this includes but is not limited to the
                                     * case of an unknown username); sent in reply to a &lt;response/&gt;
                                     * element or an &lt;auth/&gt; element with initial response data. */
    SaslTemporaryAuthFailure,       /**< The authentication failed because of a temporary error condition
                                     * within the receiving entity; sent in reply to an &lt;auth/&gt; element
                                     * or &lt;response/&gt; element. */
    NonSaslConflict,                /**< XEP-0078: Resource Conflict */
    NonSaslNotAcceptable,           /**< XEP-0078: Required Information Not Provided */
    NonSaslNotAuthorized            /**< XEP-0078: Incorrect Credentials */
  };

  /**
   * Identifies log sources.
   */
  enum LogArea
  {
    LogAreaClassParser                = 0x00001, /**< Log messages from Parser. */
    LogAreaClassConnectionTCPBase     = 0x00002, /**< Log messages from ConnectionTCPBase. */
    LogAreaClassClient                = 0x00004, /**< Log messages from Client. */
    LogAreaClassClientbase            = 0x00008, /**< Log messages from ClientBase. */
    LogAreaClassComponent             = 0x00010, /**< Log messages from Component. */
    LogAreaClassDns                   = 0x00020, /**< Log messages from DNS. */
    LogAreaClassConnectionHTTPProxy   = 0x00040, /**< Log messages from ConnectionHTTPProxy */
    LogAreaClassConnectionSOCKS5Proxy = 0x00080, /**< Log messages from ConnectionHTTPProxy */
    LogAreaClassConnectionTCPClient   = 0x00100, /**< Log messages from ConnectionTCPClient. */
    LogAreaClassConnectionTCPServer   = 0x00200, /**< Log messages from ConnectionTCPServer. */
    LogAreaClassS5BManager            = 0x00400, /**< Log messages from SOCKS5BytestreamManager. */
    LogAreaAllClasses                 = 0x01FFF, /**< All log messages from all the classes. */
    LogAreaXmlIncoming                = 0x02000, /**< Incoming XML. */
    LogAreaXmlOutgoing                = 0x04000, /**< Outgoing XML. */
    LogAreaUser                       = 0x80000, /**< User-defined sources. */
    LogAreaAll                        = 0xFFFFF  /**< All log sources. */
  };

  /**
   * Describes a log message's severity.
   */
  enum LogLevel
  {
    LogLevelDebug,                  /**< Debug messages. */
    LogLevelWarning,                /**< Non-crititcal warning messages. */
    LogLevelError                   /**< Critical, unrecoverable errors. */
  };

  /**
   * The possible Message Events according to XEP-0022.
   */
  enum MessageEventType
  {
    MessageEventCancel    = 0,      /**< Cancels the 'Composing' event. */
    MessageEventOffline   = 1,      /**< Indicates that the message has been stored offline by the
                                     * intended recipient's server. */
    MessageEventDelivered = 2,      /**< Indicates that the message has been delivered to the
                                     * recipient. */
    MessageEventDisplayed = 4,      /**< Indicates that the message has been displayed */
    MessageEventComposing = 8       /**< Indicates that a reply is being composed. */
  };

  /**
   * The possible Chat States according to XEP-0085.
   */
  enum ChatStateType
  {
    ChatStateActive       =  1,     /**< User is actively participating in the chat session. */
    ChatStateComposing    =  2,     /**< User is composing a message. */
    ChatStatePaused       =  4,     /**< User had been composing but now has stopped. */
    ChatStateInactive     =  8,     /**< User has not been actively participating in the chat session. */
    ChatStateGone         = 16      /**< User has effectively ended their participation in the chat
                                     * session. */
  };

  /**
   * Describes the possible error conditions for resource binding.
   */
  enum ResourceBindError
  {
    RbErrorUnknownError,            /**< An unknown error occured. */
    RbErrorBadRequest,              /**< Resource identifier cannot be processed. */
    RbErrorNotAllowed,              /**< Client is not allowed to bind a resource. */
    RbErrorConflict                 /**< Resource identifier is in use. */
  };

  /**
   * Describes the possible error conditions for session establishemnt.
   */
  enum SessionCreateError
  {
    ScErrorUnknownError,            /**< An unknown error occured. */
    ScErrorInternalServerError,     /**< Internal server error. */
    ScErrorForbidden,               /**< username or resource not allowed to create session. */
    ScErrorConflict                 /**< Server informs newly-requested session of resource
                                     * conflict. */
  };

  /**
   * Currently implemented message session filters.
   */
  enum MessageSessionFilter
  {
    FilterMessageEvents    = 1,     /**< Message Events (XEP-0022) */
    FilterChatStates       = 2      /**< Chat State Notifications (XEP-0085) */
  };

  /**
   * Defined MUC room affiliations. See XEP-0045 for default privileges.
   */
  enum MUCRoomAffiliation
  {
    AffiliationNone,                /**< No affiliation with the room. */
    AffiliationOutcast,             /**< The user has been banned from the room. */
    AffiliationMember,              /**< The user is a member of the room. */
    AffiliationOwner,               /**< The user is a room owner. */
    AffiliationAdmin                /**< The user is a room admin. */
  };

  /**
   * Defined MUC room roles. See XEP-0045 for default privileges.
   */
  enum MUCRoomRole
  {
    RoleNone,                       /**< Not present in room. */
    RoleVisitor,                    /**< The user visits a room. */
    RoleParticipant,                /**< The user has voice in a moderatd room. */
    RoleModerator                   /**< The user is a room moderator. */
  };

  /**
   * Configuration flags for a room.
   */
  enum MUCRoomFlag
  {
    FlagPasswordProtected  =    1,  /**< Password-protected room.*/
    FlagPublicLogging      =    2,  /**< Room conversation is publicly logged. */
    FlagHidden             =    4,  /**< Hidden room. */
    FlagMembersOnly        =    8,  /**< Members-only room. */
    FlagModerated          =   16,  /**< Moderated room. */
    FlagNonAnonymous       =   32,  /**< Non-anonymous room. */
    FlagOpen               =   64,  /**< Open room. */
    FlagPersistent         =  128,  /**< Persistent room .*/
    FlagPublic             =  256,  /**< Public room. */
    FlagSemiAnonymous      =  512,  /**< Semi-anonymous room. */
    FlagTemporary          = 1024,  /**< Temporary room. */
    FlagUnmoderated        = 2048,  /**< Unmoderated room. */
    FlagUnsecured          = 4096,  /**< Unsecured room. */
    FlagFullyAnonymous     = 8192   /**< Fully anonymous room. */
  };

  /**
   * Configuration flags for a user.
   */
  enum MUCUserFlag
  {
    UserSelf               =   1,   /**< Other flags relate to the current user him/herself. */
    UserNickChanged        =   2,   /**< The user changed his/her nickname. */
    UserKicked             =   4,   /**< The user has been kicked. */
    UserBanned             =   8,   /**< The user has been banned. */
    UserAffiliationChanged =  16,   /**< The user's affiliation with the room changed. */
    UserRoomDestroyed      =  32    /**< The room has been destroyed. */
  };	
  
  /**
   * Describes possible subscribtion types according to RFC 3921, Section 9.
   */
  enum SubscriptionEnum
  {
    S10nNone,            /**< Contact and user are not subscribed to each other, and
                           * neither has requested a subscription from the other. */
    S10nNoneOut,         /**< Contact and user are not subscribed to each other, and
                           * user has sent contact a subscription request but contact
                           * has not replied yet. */
    S10nNoneIn,          /**< Contact and user are not subscribed to each other, and
                           * contact has sent user a subscription request but user has
                           * not replied yet (note: contact's server SHOULD NOT push or
                           * deliver roster items in this state, but instead SHOULD wait
                           * until contact has approved subscription request from user). */
    S10nNoneOutIn,       /**< Contact and user are not subscribed to each other, contact
                           * has sent user a subscription request but user has not replied
                           * yet, and user has sent contact a subscription request but
                           * contact has not replied yet. */
    S10nTo,              /**< User is subscribed to contact (one-way). */
    S10nToIn,            /**< User is subscribed to contact, and contact has sent user a
                           * subscription request but user has not replied yet. */
    S10nFrom,            /**< Contact is subscribed to user (one-way). */
    S10nFromOut,         /**< Contact is subscribed to user, and user has sent contact a
                           * subscription request but contact has not replied yet. */
    S10nBoth              /**< User and contact are subscribed to each other (two-way). */
  };
]]

-- Basic jabber connections
-- %TESTCASE{"test_jabber_login_basics", func = "test_jabber_login_basics", input = {jid="lixizhi1@localhost", password = "1234567", networkhost=""},}%
function test_jabber_login_basics(input)
	log("begin test ... \n")
	local jc = JabberClientManager.CreateJabberClient(input.jid);
	if(not jc:GetIsAuthenticated()) then
		if(true) then -- 20000 milliseconds
			--jc.User = username;
			jc.Password = input.password;
			--jc.Server = servername;
			
			--if(input.networkhost ~="" ) then
				--jc.NetworkHost = input.networkhost;
			--end	
			
			jc:ResetAllEventListeners();
			-- bind event to map 3d system chat
			
			
			jc:AddEventListener("JE_OnConnect", "commonlib.echo(msg)");
			jc:AddEventListener("JE_OnAuthenticate", "commonlib.echo(msg)");
			jc:AddEventListener("JE_OnDisconnect", "commonlib.echo(msg)");
			jc:AddEventListener("JE_OnAuthError", "commonlib.echo(msg)");
			jc:AddEventListener("JE_OnError", "commonlib.echo(msg)");
			
			jc:AddEventListener("JE_OnMessage", "commonlib.echo(msg)");
			jc:AddEventListener("JE_OnStanzaMessageChat", "commonlib.echo(msg)");
			
			jc:AddEventListener("JE_OnRoster", "commonlib.echo(msg)");
			jc:AddEventListener("JE_OnSubscriptionRequest", "commonlib.echo(msg)");
			jc:AddEventListener("JE_OnUnsubscriptionRequest", "commonlib.echo(msg)");
			
			jc:AddEventListener("JE_OnSelfPresence", "commonlib.echo(msg)");
			jc:AddEventListener("JE_OnSubscriptionRequest", "commonlib.echo(msg)");
			jc:AddEventListener("JE_OnUnsubscriptionRequest", "commonlib.echo(msg)");
			jc:AddEventListener("JE_OnRosterPresence", "commonlib.echo(msg)");
			
			-- Allow plaintext authentication
			jc.PlaintextAuth = true;
			--jc.AutoStartTLS = false;
			--jc.RequiresSASL = false;
			
			-- open the connection
			log("begin: connecting JID:")
			log(tostring(input.jid).."\n")
			
			if(jc:Connect()) then
				log("connection established\n")
			else
				log("connection failed. \n")
			end	
		else
			log("connecting ... \n");
		end	
	else
		log("connected "..jc.User..jc.Server.."\n");
	end	
end

-- get roster
-- %TESTCASE{"test_jabber_get_roster", func = "test_jabber_get_roster", input = {jid="lixizhi1@localhost"},}%
function test_jabber_get_roster(input)
	local jc = JabberClientManager.CreateJabberClient(input.jid);
	if(jc:GetIsAuthenticated()) then
		local rostor = jc:GetRoster();
		if(type(rostor) == "string") then
			rostor = commonlib.LoadTableFromString(rostor);
		end
		if(roster) then
			log("fetching roster...\n");
			local _, item
			for _, item in ipairs(roster) do
				commonlib.log("JID: %s; name:%s; groups: subscription:%d", item.jid, item.name, item.subscription);
				local _, group 
				for _, group in ipairs(item.groups) do
					commonlib.log(group);
				end
				local _, resource
				for _, resource in ipairs(item.resources) do
					commonlib.log(resource);
				end
				log("\n");
			end
		end
	else
		log("not authed\n")
	end
end

-- get subscription
-- %TESTCASE{"test_jabber_subscription", func = "test_jabber_subscription", input = {jid="lixizhi1@localhost", subscribeto="lixizhi2@localhost"},}%
function test_jabber_subscription(input)
	local jc = JabberClientManager.CreateJabberClient(input.jid);
	if(jc:GetIsAuthenticated()) then
		log("sending subscribe request ...\n");
		-- jid, name, group, message
		jc:Subscribe(input.subscribeto, "name", "mygroup", "I am "..input.jid)
	else
		log("not authed\n")
	end
end

-- send a normal chat message. One needs to establish a connection prior to this. 
-- %TESTCASE{"test_jabber_send_message", func = "test_jabber_send_message", input = {client="lixizhi1@localhost", to="lixizhi2@localhost", body="ping..."},}%
function test_jabber_send_message(input)
	local jc = JabberClientManager.CreateJabberClient(input.client);
	if(jc:GetIsAuthenticated()) then
		log("sending...\n")
		jc:Message(input.to, input.body);
	else
		log("not authed\n")
	end
end


local CreateAccountInfo;
-- create new account. Note this only works with standard jabber server. the current paraworld platform disables external registration. 
-- %TESTCASE{"test_jabber_createaccount", func = "test_jabber_createaccount", input = {domain="localhost", username="lixizhi1", password = "1234567"},}%
function test_jabber_createaccount(input)
	CreateAccountInfo = input;
	local jc = JabberClientManager.CreateJabberClient(input.domain);
	if(not jc:GetIsAuthenticated()) then
		jc:Connect()
		jc:AddEventListener("JE_OnConnect", "test_jabber_createaccount_onconnect();");
	end
end

function test_jabber_createaccount_onconnect()
	log("creating account ... \n")
	local jc = JabberClientManager.CreateJabberClient(CreateAccountInfo.domain);
	jc:RegisterCreateAccount(CreateAccountInfo.username, CreateAccountInfo.password);
end



-- send a NPL message. Remember to setup string map for efficient network calls. 
-- %TESTCASE{"test_jabber_send_npl_message", func = "test_jabber_send_npl_message", input = {from="lixizhi1@localhost", to="lixizhi2@localhost", npl_file="script/test/TestJabber.lua", msg="{a=1, b=10}"},}%
function test_jabber_send_npl_message(input)
	
	-- add string a string mapping. We will automatically encode NPL filename string if it is in this string map. It means shorter message sent over the network. 
	-- use AddStringMap whenever you want to add a string to the map. Please note, that the sender and the receiver must maintain the same string map in memory in order to have consistent string translation result.
	-- the function is static, it will apply to all client instances. 
	JabberClientManager.ClearStringMap();
	JabberClientManager.AddStringMap(1, "script/test/TestJabber.lua");
	-- TODO: add any string map as you like once and for all. and make sure that the server has the same mapping.  It is better to fetch this via local or remote XML file.
	JabberClientManager.AddStringMap(2, "script/kids/3DMapSystemNetwork/JGSL_client.lua");
	JabberClientManager.AddStringMap(3, "script/kids/3DMapSystemNetwork/JGSL_server.lua");
	
	local jc = JabberClientManager.CreateJabberClient(input.from);
	if(jc:GetIsAuthenticated()) then
		log("sending...\n")
		jc:activate(input.to..":"..input.npl_file, input.msg)
	else
		log("not authed\n")
	end
end

-- the receiver for remote activation. 
local function activate()
	log("NPL jabber activation:")
	commonlib.echo(msg)
end
NPL.this(activate)