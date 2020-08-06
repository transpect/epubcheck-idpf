<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:xs="http://www.w3.org/2001/XMLSchema" 
  xmlns:c="http://www.w3.org/ns/xproc-step" 
  xmlns:cx="http://xmlcalabash.com/ns/extensions" 
  xmlns:svrl="http://purl.oclc.org/dsdl/svrl" 
  xmlns:s="http://purl.oclc.org/dsdl/schematron" 
  xmlns:tr="http://transpect.io" 
  xmlns:jhove="http://hul.harvard.edu/ois/xml/ns/jhove"
  exclude-result-prefixes="xs jhove cx c" version="2.0">
  
  <!--  * 
        * This stylesheet converts the output of the command line version 
        * and the calabash extension version of epubcheck to SVRL.  
        * -->

  <!-- default sourcepath for svrl asserts -->
  <xsl:param name="svrl-srcpath"/>
  <xsl:param name="epubfile-path"/>

  <!-- identity template -->
  <xsl:template match="*|@*">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="/jhove:jhove|/cx:document">
    <svrl:schematron-output tr:rule-family="{string-join(('epubcheck', @epubcheck-version), ' ')}" tr:step-name="epubcheck">
      <xsl:apply-templates/>
    </svrl:schematron-output>
  </xsl:template>
  
  <!--  *
        * JSTOR/Harvard Object Validation Environment (output of calabash extension)
        *-->
  
  <xsl:template match="jhove:*">
    <xsl:apply-templates select="*"/>
  </xsl:template>
  
  <xsl:template match="jhove:message">
    <!-- strip severity from text output -->
    <xsl:variable name="severity" select="@severity" as="attribute(severity)"/>
    <xsl:variable name="error-type" select="@subMessage" as="attribute(subMessage)"/>
    <svrl:failed-assert test="{ancestor::jhove:repInfo/@uri}" 
                         id="{if (matches($error-type, '\S')) 
                              then concat('epubcheck_', $error-type) 
                              else concat('epubcheck_', generate-id()) }" 
                       role="{$severity}" location="{$svrl-srcpath}">
      <svrl:text>
        <s:span class="srcpath">
          <xsl:value-of select="$svrl-srcpath"/>
        </s:span>
        <s:span class="epubcheck">
          <xsl:apply-templates/>
        </s:span>
      </svrl:text>
    </svrl:failed-assert>
  </xsl:template>
  
  <!--  *
        * parse command line output of epubcheck
        *-->

  <!-- drop empty lines and status messages-->
	<xsl:template match="c:line[not(text()) or matches(., '(^Check\sfinished.+|EpubCheck (mit (Fehlern|Warnungen) )?abgeschlossen\.)', 'i')]" priority="10"/>

  <!-- process errors -->
  <xsl:template match="c:result">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- construct error messages -->
  <xsl:template match="c:line[text()][not(starts-with(., 'EPUBCheck'))]">
    <!-- strip severity from text output -->
    <xsl:variable name="severity" select="if (matches(text(), '^\p{Lu}+\(\p{Lu}{3}-\d{3}\)')) 
                                          then lower-case(replace(text(), '^(\p{Lu}+)\(.+$', '$1')) 
                                          else  lower-case(replace(text(), '^([A-Z]+):.+$', '$1'))"/>
    <xsl:variable name="error-type" select="s:error-type(.)"/>
    <svrl:failed-assert test="{$epubfile-path}" 
      id="{if (matches($error-type, '\S')) 
            then concat('epubcheck_', $error-type) 
            else concat('epubcheck_', generate-id()) }" 
      role="{$severity}" location="{$svrl-srcpath}">
      <svrl:text>
        <s:span class="srcpath">
          <xsl:value-of select="$svrl-srcpath"/>
        </s:span>
        <s:span class="epubcheck">
          <xsl:value-of select="."/>
        </s:span>
      </svrl:text>
    </svrl:failed-assert>
  </xsl:template>

  <xsl:template match="svrl:failed-assert/@id[. = 'sch_styles_undefined']">
    <xsl:attribute name="{name()}" select="concat(., '_', ../svrl:text/s:span[@class = 'style-name'])"/>
  </xsl:template>

  <xsl:function name="s:error-type" as="xs:string?">
    <xsl:param name="error-message" as="xs:string"/>
    
    <xsl:choose>
      <!-- EPUB Check 4 messages -->
      <xsl:when test="$error-message[matches(., '^\p{Lu}+\(\p{Lu}{3}-\d{3}\)')]">
        <xsl:value-of select="replace($error-message, '^\p{Lu}+\((\p{Lu}{3}-\d{3})\).+$', '$1')"/>
      </xsl:when>
      <!-- EPUB Check 3 messages -->
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="$error-message[matches(., 'duplicate id', 'i')]">
            <xsl:value-of select="'duplicate_id'"/>
          </xsl:when>
          <xsl:when test="$error-message[matches(., 'could not parse', 'i')]">
            <xsl:value-of select="'parse_error'"/>
          </xsl:when>
          <xsl:when test="$error-message[matches(., 'fragment identifier is not defined', 'i')]">
            <xsl:value-of select="'invalid_fragment_identifier'"/>
          </xsl:when>
          <xsl:when test="$error-message[matches(., 'date value', 'i')]">
            <xsl:value-of select="'metadata_date_value'"/>
          </xsl:when>
          <xsl:when test="$error-message[matches(., 'dc:identifier', 'i')]">
            <xsl:value-of select="'metadata_dc_identifier'"/>
          </xsl:when>
          <xsl:when test="$error-message[matches(., 'dc:creator', 'i')]">
            <xsl:value-of select="'metadata_dc_creator'"/>
          </xsl:when>
          <xsl:when test="$error-message[matches(., 'not allowed here; expected the element end-tag', 'i')]">
            <xsl:value-of select="'wrong_element'"/>
          </xsl:when>
          <xsl:when test="$error-message[matches(., 'incomplete; expected', 'i')]">
            <xsl:value-of select="'incomplete_element'"/>
          </xsl:when>
          <xsl:when test="$error-message[matches(., 'is not allowed in prolog', 'i')]">
            <xsl:value-of select="'content_in_prolog'"/>
          </xsl:when>
          <xsl:when test="$error-message[matches(., 'is not allowed in trailing section', 'i')]">
            <xsl:value-of select="'content_in_trailing_section'"/>
          </xsl:when>
          <xsl:when test="$error-message[matches(., 'prefix.+element', 'i')]">
            <xsl:value-of select="'unbound_prefix_element'"/>
          </xsl:when>
          <xsl:when test="$error-message[matches(., 'missing required attribute', 'i')]">
            <xsl:value-of select="'missing_attribute'"/>
          </xsl:when>
          <xsl:when test="$error-message[matches(., 'not allowed here; expected attribute', 'i')]">
            <xsl:value-of select="'wrong_attribute'"/>
          </xsl:when>
          <xsl:when test="$error-message[matches(., 'must be followed by either attribute specifications', 'i')]">
            <xsl:value-of select="'missing_closing_element'"/>
          </xsl:when>
          <xsl:when test="$error-message[matches(., 'prefix.+attribute', 'i')]">
            <xsl:value-of select="'unbound_prefix_attribute'"/>
          </xsl:when>
          <xsl:when test="$error-message[matches(., 'is invalid; must be an XML name without colons', 'i')]">
            <xsl:value-of select="'invalid_id_value'"/>
          </xsl:when>
          <xsl:when test="$error-message[matches(., 'attribute.+associated with an element type', 'i')]">
            <xsl:value-of select="'invalid_attribute_value_$lt;'"/>
          </xsl:when>
          <xsl:when test="$error-message[matches(., 'UTF-16 encodings are allowed', 'i')]">
            <xsl:value-of select="'wrong_encoding'"/>
          </xsl:when>
          <xsl:when test="$error-message[matches(., 'Malformed byte sequence', 'i')]">
            <xsl:value-of select="'malformed_byte_sequence'"/>
          </xsl:when>
          <xsl:when test="$error-message[matches(., 'Any Publication Resource that is an XML-Based', 'i')]">
            <xsl:value-of select="'wrong_xml_document_type'"/>
          </xsl:when>
          <xsl:when test="$error-message[matches(., 'referenced resource missing', 'i')]">
            <xsl:value-of select="'missing_referenced_resource'"/>
          </xsl:when>
          <xsl:when test="$error-message[matches(., 'name contains characters disallowed', 'i')]">
            <xsl:value-of select="'invalid_characters_in_filename'"/>
          </xsl:when>
          <xsl:when test="$error-message[matches(., 'name contains non-ascii characters', 'i')]">
            <xsl:value-of select="'non_ascii_characters_in_filename'"/>
          </xsl:when>
          <xsl:when test="$error-message[matches(., 'contains spaces. Consider changing filename', 'i')]">
            <xsl:value-of select="'spaces_in_filename'"/>
          </xsl:when>
          <xsl:when test="$error-message[matches(., 'name is not allowed to end with', 'i')]">
            <xsl:value-of select="'dot_as_filename_ending'"/>
          </xsl:when>
          <xsl:when test="$error-message[matches(., 'ZIP header', 'i')]">
            <xsl:value-of select="'corrupted_zip_header'"/>
          </xsl:when>
          <xsl:when test="$error-message[matches(., 'read header', 'i')]">
            <xsl:value-of select="'header_unreadable'"/>
          </xsl:when>
          <xsl:when test="$error-message[matches(., 'of first filename in archive must be', 'i')]">
            <xsl:value-of select="'wrong_mimetype_file'"/>
          </xsl:when>
          <xsl:when test="$error-message[matches(., 'entry missing or not the first in archive', 'i')]">
            <xsl:value-of select="'wrong_mimetype_position'"/>
          </xsl:when>
          <xsl:when test="$error-message[matches(., 'field length for first filename must be 0', 'i')]">
            <xsl:value-of select="'invalid_first_character_in_mimetype'"/>
          </xsl:when>
          <xsl:when test="$error-message[matches(., 'Mimetype contains wrong type', 'i')]">
            <xsl:value-of select="'wrong_mimetype_mediatype'"/>
          </xsl:when>
          <xsl:when test="$error-message[matches(., 'Mimetype file should contain only the string', 'i')]">
            <xsl:value-of select="'invalid_content_of_mimetype'"/>
          </xsl:when>
          <xsl:when test="$error-message[matches(., 'container.xml resource is missing', 'i')]">
            <xsl:value-of select="'missing_container_xml'"/>
          </xsl:when>
          <xsl:when test="$error-message[matches(., 'No rootfiles with media type', 'i')]">
            <xsl:value-of select="'no_rootfiles_in_cointainer_xml'"/>
          </xsl:when>
          <xsl:when test="$error-message[matches(., 'not found in zip file', 'i')]">
            <xsl:value-of select="'package_element_not_found'"/>
          </xsl:when>
          <xsl:when test="$error-message[matches(., 'non-standard image resource', 'i')]">
            <xsl:value-of select="'media_wrong_image_type'"/>
          </xsl:when>
          <xsl:when test="$error-message[matches(., 'exists in the zip file, but is not declared in the OPF file', 'i')]">
            <xsl:value-of select="'undeclared_item_in_zip_file'"/>
          </xsl:when>
          <xsl:when test="$error-message[matches(., 'referenced resource missing in the package', 'i')]">
            <xsl:value-of select="'undeclared_item_in_zip_file'"/>
          </xsl:when>
          <xsl:when test="$error-message[matches(., 'resource.+is missing', 'i')]">
            <xsl:value-of select="'missing_resource'"/>
          </xsl:when>
          <xsl:when test="$error-message[matches(., 'attribute with no value', 'i')]">
            <xsl:value-of select="'attribute_no_value'"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="''"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

</xsl:stylesheet>
