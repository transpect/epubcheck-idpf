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
    
    You can choose between invoking epubcheck with command line or as calabash 
    extension (preferred). If you want to use the calabash extension of epubcheck, you have 
    to checkout <code>https://github.com/transpect/epubcheck-extension/trunk</code> to
    calabash/extensions/transpect/epubcheck-extension and set the parameter <code>interface</code> 
    to the value <code>extension</code>.
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

  <p:option name="epubcheck-version" select="'4.1.1'" required="false">
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
  
  <p:option name="interface" select="'commandline'"><!-- commandline|extension-->
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      Whether to invoke epubcheck via commandline or with the calabash extension. 
      You have to add the calabash extension manually to your calabash distro:
      <pre>
        <code>$ svn co https://github.com/transpect/epubcheck-extension/trunk calabash/extensions/transpect/epubcheck-extension</code>
      </pre>
      You should also ensure to use the latest Calabash, at least version 1.1.21.
      Please note also that epubcheck was patched and compiled to run with Saxon version 9.8.0.12.
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
  
  <p:option name="status-dir-uri" select="concat( resolve-uri( $debug-dir-uri ), '/status' )">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <h3>Option: <code>status-dir-uri</code></h3>
      <p>This variable expects an URI. The file (see option above) is saved to this URI.</p>
    </p:documentation>
  </p:option>
  
  <p:import href="epubcheck-command-line.xpl"/>

  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
  <p:import href="http://transpect.io/calabash-extensions/epubcheck-extension/epubcheck-declaration.xpl"/>
  
  <p:import href="http://transpect.io/xproc-util/file-uri/xpl/file-uri.xpl"/>
  <p:import href="http://transpect.io/xproc-util/store-debug/xpl/store-debug.xpl" />
  <p:import href="http://transpect.io/xproc-util/simple-progress-msg/xpl/simple-progress-msg.xpl"/>

  <p:variable name="fallback-version" select="'4.1.1'"/>
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

  <tr:file-uri name="epub-file">
    <p:with-option name="filename" select="$epubfile-path"/>
    <p:input port="catalog">
      <p:document href="http://this.transpect.io/xmlcatalog/catalog.xml"/>
    </p:input>
    <p:input port="resolver">
      <p:document href="http://transpect.io/xslt-util/xslt-based-catalog-resolver/xsl/resolve-uri-by-catalog.xsl"/>
    </p:input>
  </tr:file-uri>
  
  <p:choose name="check-group">
    <p:when test="$interface eq 'commandline'">
      
      <tr:epubcheck-command-line>
        <p:with-option name="epubcheck-path" select="$epubcheck-path"/>
        <p:with-option name="epubfile-path" select="/c:result/@os-path">
          <p:pipe port="result" step="epub-file"/>
        </p:with-option>
        <p:with-option name="fallback-version" select="$fallback-version"/>
        <p:with-option name="svrl-srcpath" select="$svrl-srcpath"/>
        <p:with-option name="debug" select="$debug"/>
        <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
      </tr:epubcheck-command-line>
      
      <tr:store-debug pipeline-step="epubcheck/stdout">
        <p:with-option name="active" select="$debug"/>
        <p:with-option name="base-uri" select="$debug-dir-uri"/>
      </tr:store-debug>
      
    </p:when>
    <p:otherwise>
      
      <tr:epubcheck>
        <p:with-option name="href" select="$epubfile-path"/>
      </tr:epubcheck>
      
      <tr:store-debug pipeline-step="epubcheck/jhove">
        <p:with-option name="active" select="$debug"/>
        <p:with-option name="base-uri" select="$debug-dir-uri"/>
      </tr:store-debug>
      
      <p:xslt name="convert-epubcheck-output">
        <p:input port="stylesheet">
          <p:document href="../xsl/epubcheck.xsl"/>
        </p:input>
        <p:with-param name="svrl-srcpath" select="$svrl-srcpath"/>
        <p:with-param name="epubfile-path" select="$epubfile-path"/>
      </p:xslt>
      
    </p:otherwise>
  </p:choose>

  <tr:store-debug pipeline-step="epubcheck/epubcheck.svrl">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>
  
  <tr:simple-progress-msg file="epubcheck-start.txt" cx:depends-on="check-group">
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
