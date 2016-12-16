<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step 
  xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:c="http://www.w3.org/ns/xproc-step" 
  xmlns:cx="http://xmlcalabash.com/ns/extensions"
  xmlns:tr="http://transpect.io"
  xmlns:pxf="http://exproc.org/proposed/steps/file"
  version="1.0" 
  name="epubcheck" 
  type="tr:epubcheck-idpf">

  <p:documentation xmlns="http://www.w3.org/1999/xhtml">
    An implementation of epubcheck to provide it's results as Schematron SVRL.
    Provide the path to the EPUB file with the option <code>epubfile-path</code>.
  </p:documentation>

  <p:output port="result" primary="true">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <h3>Output port: <code>result</code></h3>
      <p>Provides the result of the epubcheck as Schematron SVRL file</p>
    </p:documentation>
  </p:output>

  <p:option name="epubfile-path" required="true">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <h3>Option: <code>epubfile-path</code></h3>
      <p>Expects the path to the EPUB file.</p>
    </p:documentation>
  </p:option>

  <p:option name="epubcheck-version" select="'4.0.2'" required="false">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <h3>Option: <code>epubcheck-version</code></h3>
      <p>If you want to use another epubcheck version as shipped within this repository, provide the name of the version. Currently 4.0.2 and 3.0.1 are available.</p>
    </p:documentation>
  </p:option>
  
  <p:option name="svrl-srcpath" select="'BC_orphans'">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <h3>Option: <code>svrl-srcpath</code></h3>
      <p>XPath location of the Schematron SVRL error message. This affects also where the error message is rendered in the HTML report.</p>
    </p:documentation>
  </p:option>

  <p:option name="debug" select="'yes'">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <h3>Option: <code>debug</code></h3>
      <p>Used to switch debug mode on or off. Pass 'yes' to enable debug mode.</p>
    </p:documentation>
  </p:option> 
  <p:option name="debug-dir-uri" select="'debug'">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <h3>Option: <code>debug-dir-uri</code></h3>
      <p>Expects a file URI of the directory that should be used to store debug information.</p>
    </p:documentation>
  </p:option>
  
  <p:option name="status-dir-uri" select="'status'">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <h3>Option: <code>status-dir-uri</code></h3>
      <p>This variable expects an URI. The file (see option above) is saved to this URI.</p>
    </p:documentation>
  </p:option>

  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
  <p:import href="http://transpect.io/xproc-util/file-uri/xpl/file-uri.xpl"/>
  <p:import href="http://transpect.io/xproc-util/store-debug/xpl/store-debug.xpl" />
  <p:import href="http://transpect.io/xproc-util/simple-progress-msg/xpl/simple-progress-msg.xpl"/>

  <p:variable name="fallback-version" select="'4.0.2'"/>
  <p:variable name="epubcheck-path" 
    				select="concat('http://transpect.io/epubcheck-idpf/', ($epubcheck-version[normalize-space()], $fallback-version)[1],'/bin/epubcheck.jar')"/>

  <tr:simple-progress-msg file="epubcheck-start.txt" name="msg-epubcheck-start">
    <p:input port="msgs">
      <p:inline>
        <c:messages>
          <c:message xml:lang="en">Starting EPUB check</c:message>
          <c:message xml:lang="de">Beginne EPUB-Prüfung</c:message>
        </c:messages>
      </p:inline>
    </p:input>
    <p:with-option name="status-dir-uri" select="$status-dir-uri"/>
  </tr:simple-progress-msg>
  
  <cx:message>
    <p:with-option name="message" select="'[info] epubcheck path: ', $epubcheck-path"/>
  </cx:message>

  <tr:file-uri name="jar-file">
    <p:with-option name="filename" select="$epubcheck-path"/>
    <p:input port="catalog">
      <p:document href="http://this.transpect.io/xmlcatalog/catalog.xml"/>
    </p:input>
    <p:input port="resolver">
      <p:document href="http://transpect.io/xslt-util/xslt-based-catalog-resolver/xsl/resolve-uri-by-catalog.xsl"/>
    </p:input>
  </tr:file-uri>
  
  <tr:file-uri name="epub-file">
    <p:with-option name="filename" select="$epubfile-path"/>
    <p:input port="catalog">
      <p:document href="http://this.transpect.io/xmlcatalog/catalog.xml"/>
    </p:input>
    <p:input port="resolver">
      <p:document href="http://transpect.io/xslt-util/xslt-based-catalog-resolver/xsl/resolve-uri-by-catalog.xsl"/>
    </p:input>
  </tr:file-uri>
  
  	<pxf:info name="jar-info" fail-on-error="false">
	  	<p:with-option name="href" select="/*/@local-href">
	  		<p:pipe port="result" step="jar-file"/>
	  	</p:with-option>
	  </pxf:info>
  	
  	<p:choose name="checked-jar-file">
  		<p:xpath-context>
  			<p:pipe port="result" step="jar-info"/>
  		</p:xpath-context>
  		<p:when test="/*/c:file[@readable = 'true']">
  			<p:output port="result">
  				<p:pipe port="result" step="orig-result"/>
  			</p:output>
  			<p:identity name="orig-result">
  				<p:input port="source">
  					<p:pipe port="result" step="jar-file"/>
  				</p:input>
  			</p:identity>
  			<p:sink/>
		 </p:when>
  		<p:otherwise>
  			<p:output port="result">
  				<p:pipe port="result" step="jar-file-fallback"/>
  			</p:output>
  			<cx:message>
   				 <p:with-option name="message" select="'######### [info] jar in epubcheck path: ', $epubcheck-path, ' not found. Used fallback version ', $fallback-version,' instead.'"/>
  			</cx:message>
  			<tr:file-uri name="jar-file-fallback">
			    <p:with-option name="filename" select="concat('http://transpect.io/epubcheck-idpf/', $fallback-version,'/bin/epubcheck.jar')"/>
			    <p:input port="catalog">
			      <p:document href="http://this.transpect.io/xmlcatalog/catalog.xml"/>
			    </p:input>
			    <p:input port="resolver">
			      <p:document href="http://transpect.io/xslt-util/xslt-based-catalog-resolver/xsl/resolve-uri-by-catalog.xsl"/>
			    </p:input>
			  </tr:file-uri>
  			<p:sink/>
  		</p:otherwise>
  </p:choose>
	
  <p:group name="do-check">
    <p:variable name="jar" select="/*/@os-path">
      <p:pipe port="result" step="checked-jar-file"/>
    </p:variable>
    <p:variable name="epub" select="/*/@os-path">
      <p:pipe port="result" step="epub-file"/>
    </p:variable>
    
  	<p:sink/>
  	
    <p:exec name="execute-epubcheck" result-is-xml="false" errors-is-xml="false" wrap-error-lines="true"
      wrap-result-lines="true" cx:depends-on="msg-epubcheck-start">
      <p:input port="source">
        <p:empty/>
      </p:input>
      <p:with-option name="command" select="'java'"/>
      <p:with-option name="args" select="concat('-jar ', $jar, ' ', $epub)"/>
    </p:exec>

    <p:sink/>

    <p:wrap-sequence wrapper="document" wrapper-prefix="cx" wrapper-namespace="http://xmlcalabash.com/ns/extensions">
      <p:input port="source">
        <p:pipe port="errors" step="execute-epubcheck"/>
      </p:input>
    </p:wrap-sequence>

    <p:add-attribute match="/cx:document" attribute-name="epubcheck-path">
      <p:with-option name="attribute-value" select="$epubcheck-path"/>
    </p:add-attribute>

    <p:add-attribute match="/cx:document" attribute-name="epubfile-path">
      <p:with-option name="attribute-value" select="$epub"/>
    </p:add-attribute>

    <tr:store-debug pipeline-step="epubcheck/epubcheck.out">
      <p:with-option name="active" select="$debug"/>
      <p:with-option name="base-uri" select="$debug-dir-uri"/>
    </tr:store-debug>

    <p:xslt name="convert-epubcheck-output">
      <p:input port="stylesheet">
        <p:document href="../xsl/epubcheck.xsl"/>
      </p:input>
      <p:with-param name="svrl-srcpath" select="$svrl-srcpath"/>
    </p:xslt>

    <tr:store-debug pipeline-step="epubcheck/epubcheck.svrl">
      <p:with-option name="active" select="$debug"/>
      <p:with-option name="base-uri" select="$debug-dir-uri"/>
    </tr:store-debug>
  </p:group>
  
  <tr:simple-progress-msg file="epubcheck-start.txt" cx:depends-on="do-check">
    <p:input port="msgs">
      <p:inline>
        <c:messages>
          <c:message xml:lang="en">EPUB check finished</c:message>
          <c:message xml:lang="de">EPUB-Prüfung beendet</c:message>
        </c:messages>
      </p:inline>
    </p:input>
    <p:with-option name="status-dir-uri" select="$status-dir-uri"/>
  </tr:simple-progress-msg>

</p:declare-step>
