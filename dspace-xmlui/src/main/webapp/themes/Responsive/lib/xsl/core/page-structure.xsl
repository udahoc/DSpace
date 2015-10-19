<!--

    The contents of this file are subject to the license and copyright
    detailed in the LICENSE and NOTICE files at the root of the source
    tree and available online at

    http://www.dspace.org/license/

-->
<!--
    Main structure of the page, determines where
    header, footer, body, navigation are structurally rendered.
    Rendering of the header, footer, trail and alerts

    Author: art.lowel at atmire.com
    Author: lieven.droogmans at atmire.com
    Author: ben at atmire.com
    Author: Alexey Maslov

-->

<xsl:stylesheet xmlns:i18n="http://apache.org/cocoon/i18n/2.1"
	xmlns:dri="http://di.tamu.edu/DRI/1.0/"
	xmlns:mets="http://www.loc.gov/METS/"
	xmlns:xlink="http://www.w3.org/TR/xlink/"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
	xmlns:dim="http://www.dspace.org/xmlns/dspace/dim"
	xmlns:xhtml="http://www.w3.org/1999/xhtml"
	xmlns:mods="http://www.loc.gov/mods/v3"
	xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:confman="org.dspace.core.ConfigurationManager"
	xmlns="http://www.w3.org/1999/xhtml"
	exclude-result-prefixes="i18n dri mets xlink xsl dim xhtml mods dc confman">

    <xsl:output indent="yes"/>

    <!--
        Requested Page URI. Some functions may alter behavior of processing depending if URI matches a pattern.
        Specifically, adding a static page will need to override the DRI, to directly add content.
    -->
    <xsl:variable name="request-uri" select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='request'][@qualifier='URI']"/>

    <!--
        The starting point of any XSL processing is matching the root element. In DRI the root element is document,
        which contains a version attribute and three top level elements: body, options, meta (in that order).

        This template creates the html document, giving it a head and body. A title and the CSS style reference
        are placed in the html head, while the body is further split into several divs. The top-level div
        directly under html body is called "ds-main". It is further subdivided into:
            "ds-header"  - the header div containing title, subtitle, trail and other front matter
            "ds-body"    - the div containing all the content of the page; built from the contents of dri:body
            "ds-options" - the div with all the navigation and actions; built from the contents of dri:options
            "ds-footer"  - optional footer div, containing misc information

        The order in which the top level divisions appear may have some impact on the design of CSS and the
        final appearance of the DSpace page. While the layout of the DRI schema does favor the above div
        arrangement, nothing is preventing the designer from changing them around or adding new ones by
        overriding the dri:document template.
    -->
    <xsl:template match="dri:document">
        <html class="no-js">
            <!-- First of all, build the HTML head element -->
            <xsl:call-template name="buildHead"/>
            <!-- Then proceed to the body -->

            <!--paulirish.com/2008/conditional-stylesheets-vs-css-hacks-answer-neither/-->
            <xsl:text disable-output-escaping="yes">&lt;!--[if lt IE 7 ]&gt; &lt;body class="ie6"&gt; &lt;![endif]--&gt;
                &lt;!--[if IE 7 ]&gt;    &lt;body class="ie7"&gt; &lt;![endif]--&gt;
                &lt;!--[if IE 8 ]&gt;    &lt;body class="ie8"&gt; &lt;![endif]--&gt;
                &lt;!--[if IE 9 ]&gt;    &lt;body class="ie9"&gt; &lt;![endif]--&gt;
                &lt;!--[if (gt IE 9)|!(IE)]&gt;&lt;!--&gt;&lt;body&gt;&lt;!--&lt;![endif]--&gt;</xsl:text>

            <xsl:choose>
              <xsl:when test="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='framing'][@qualifier='popup']">
                <xsl:apply-templates select="dri:body/*"/>
              </xsl:when>
                  <xsl:otherwise>
                    <div id="ds-main">
                        <!--The header div, complete with title, subtitle and other junk-->
                        <xsl:call-template name="buildHeader"/>

                        <!--The trail is built by applying a template over pageMeta's trail children. -->
                        <!-- INICIO COMENTARIO PRODIGIO - HCB - 06.10.2015 - Se deshabilita el breadcrumb que viene por defecto
                        <xsl:call-template name="buildTrail"/>
                        FIN COMENTARIO PRODIGIO -->

                        <!--javascript-disabled warning, will be invisible if javascript is enabled-->
                        <!-- INICIO COMENTARIO PRODIGIO - HCB - 06.10.2015 - Se deshabilita el mensaje de javascript
                        <div id="no-js-warning-wrapper" class="hidden">
                            <div id="no-js-warning">
                                <div class="notice failure">
                                    <xsl:text>JavaScript is disabled for your browser. Some features of this site may not work without it.</xsl:text>
                                </div>
                            </div>
                        </div>
                        FIN COMENTARIO PRODIGIO -->

                        <!--ds-content is a groups ds-body and the navigation together and used to put the clearfix on, center, etc.
                            ds-content-wrapper is necessary for IE6 to allow it to center the page content-->
                        
                        <!-- INICIO COMENTARIO PRODIGIO - HCB - 06.10.2015 - Aqui se le asigna el div o la etiqueta que enmarca todo el body -->
                        <div id="ds-content-wrapper">
                            <div id="ds-content" class="clearfix">
                                <!--
                               Goes over the document tag's children elements: body, options, meta. The body template
                               generates the ds-body div that contains all the content. The options template generates
                               the ds-options div that contains the navigation and action options available to the
                               user. The meta element is ignored since its contents are not processed directly, but
                               instead referenced from the different points in the document. -->
                                <xsl:apply-templates/>
                            </div>
                        </div>
                        <!-- FIN COMENTARIO PRODIGIO -->

                        <!--
                            The footer div, dropping whatever extra information is needed on the page. It will
                            most likely be something similar in structure to the currently given example. -->
                        <xsl:call-template name="buildFooter"/>

                    </div>

                </xsl:otherwise>
            </xsl:choose>
                <!-- Javascript at the bottom for fast page loading -->
              <xsl:call-template name="addJavascript"/>

            <xsl:text disable-output-escaping="yes">&lt;/body&gt;</xsl:text>
        </html>
    </xsl:template>

        <!-- The HTML head element contains references to CSS as well as embedded JavaScript code. Most of this
        information is either user-provided bits of post-processing (as in the case of the JavaScript), or
        references to stylesheets pulled directly from the pageMeta element. -->
    <xsl:template name="buildHead">
        <head>
            <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>

            <!-- Always force latest IE rendering engine (even in intranet) & Chrome Frame -->
            <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1"/>

            <!--  Mobile Viewport Fix
                  j.mp/mobileviewport & davidbcalhoun.com/2010/viewport-metatag
            device-width : Occupy full width of the screen in its current orientation
            initial-scale = 1.0 retains dimensions instead of zooming out if page height > device height
            maximum-scale = 1.0 retains dimensions instead of zooming in if page width < device width
            -->
            <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1"/>

            <link rel="shortcut icon">
                <xsl:attribute name="href">
                    <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/>
                    <xsl:text>/themes/</xsl:text>
                    <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='theme'][@qualifier='path']"/>
                    <xsl:text>/images/favicon.ico</xsl:text>
                </xsl:attribute>
            </link>
            <link rel="apple-touch-icon">
                <xsl:attribute name="href">
                    <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/>
                    <xsl:text>/themes/</xsl:text>
                    <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='theme'][@qualifier='path']"/>
                    <xsl:text>/images/apple-touch-icon.png</xsl:text>
                </xsl:attribute>
            </link>

            <meta name="Generator">
              <xsl:attribute name="content">
                <xsl:text>DSpace</xsl:text>
                <xsl:if test="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='dspace'][@qualifier='version']">
                  <xsl:text> </xsl:text>
                  <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='dspace'][@qualifier='version']"/>
                </xsl:if>
              </xsl:attribute>
            </meta>
            <!-- INICIO COMENTARIO PRODIGIO - HCB - 06.10.2015 - Se agregan las fuentes -->
            <link href='https://fonts.googleapis.com/css?family=Oswald:400,300' rel='stylesheet' type='text/css' />
            <link href='https://fonts.googleapis.com/css?family=Open+Sans:400,700' rel='stylesheet' type='text/css' />
            <!-- FIN COMENTARIO PRODIGIO -->
            <!-- Add stylesheets -->
            <xsl:for-each select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='stylesheet']">
                <link rel="stylesheet" type="text/css">
                    <xsl:attribute name="media">
                        <xsl:value-of select="@qualifier"/>
                    </xsl:attribute>
                    <xsl:attribute name="href">
                        <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/>
                        <xsl:text>/themes/</xsl:text>
                        <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='theme'][@qualifier='path']"/>
                        <xsl:text>/</xsl:text>
                        <xsl:value-of select="."/>
                    </xsl:attribute>
                </link>
            </xsl:for-each>

            <!-- Add syndication feeds -->
            <xsl:for-each select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='feed']">
                <link rel="alternate" type="application">
                    <xsl:attribute name="type">
                        <xsl:text>application/</xsl:text>
                        <xsl:value-of select="@qualifier"/>
                    </xsl:attribute>
                    <xsl:attribute name="href">
                        <xsl:value-of select="."/>
                    </xsl:attribute>
                </link>
            </xsl:for-each>

            <!--  Add OpenSearch auto-discovery link -->
            <xsl:if test="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='opensearch'][@qualifier='shortName']">
                <link rel="search" type="application/opensearchdescription+xml">
                    <xsl:attribute name="href">
                        <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='request'][@qualifier='scheme']"/>
                        <xsl:text>://</xsl:text>
                        <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='request'][@qualifier='serverName']"/>
                        <xsl:text>:</xsl:text>
                        <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='request'][@qualifier='serverPort']"/>
                        <xsl:value-of select="$context-path"/>
                        <xsl:text>/</xsl:text>
                        <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='opensearch'][@qualifier='autolink']"/>
                    </xsl:attribute>
                    <xsl:attribute name="title" >
                        <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='opensearch'][@qualifier='shortName']"/>
                    </xsl:attribute>
                </link>
            </xsl:if>

            <!-- The following javascript removes the default text of empty text areas when they are focused on or submitted -->
            <!-- There is also javascript to disable submitting a form when the 'enter' key is pressed. -->
                        <script type="text/javascript">
                                //Clear default text of empty text areas on focus
                                function tFocus(element)
                                {
                                        if (element.value == '<i18n:text>xmlui.dri2xhtml.default.textarea.value</i18n:text>'){element.value='';}
                                }
                                //Clear default text of empty text areas on submit
                                function tSubmit(form)
                                {
                                        var defaultedElements = document.getElementsByTagName("textarea");
                                        for (var i=0; i != defaultedElements.length; i++){
                                                if (defaultedElements[i].value == '<i18n:text>xmlui.dri2xhtml.default.textarea.value</i18n:text>'){
                                                        defaultedElements[i].value='';}}
                                }
                                //Disable pressing 'enter' key to submit a form (otherwise pressing 'enter' causes a submission to start over)
                                function disableEnterKey(e)
                                {
                                     var key;

                                     if(window.event)
                                          key = window.event.keyCode;     //Internet Explorer
                                     else
                                          key = e.which;     //Firefox and Netscape

                                     if(key == 13)  //if "Enter" pressed, then disable!
                                          return false;
                                     else
                                          return true;
                                }

                                function FnArray()
                                {
                                    this.funcs = new Array;
                                }

                                FnArray.prototype.add = function(f)
                                {
                                    if( typeof f!= "function" )
                                    {
                                        f = new Function(f);
                                    }
                                    this.funcs[this.funcs.length] = f;
                                };

                                FnArray.prototype.execute = function()
                                {
                                    for( var i=0; i <xsl:text disable-output-escaping="yes">&lt;</xsl:text> this.funcs.length; i++ )
                                    {
                                        this.funcs[i]();
                                    }
                                };

                                var runAfterJSImports = new FnArray();
            </script>

            <!-- Modernizr enables HTML5 elements & feature detects -->
            <script type="text/javascript">
                <xsl:attribute name="src">
                    <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/>
                    <xsl:text>/themes/</xsl:text>
                    <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='theme'][@qualifier='path']"/>
                    <xsl:text>/lib/js/modernizr-1.7.min.js</xsl:text>
                </xsl:attribute>&#160;</script>

            <!-- Add the title in -->
            <xsl:variable name="page_title" select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='title']" />
            <title>
                <xsl:choose>
                        <xsl:when test="starts-with($request-uri, 'page/about')">
                                <xsl:text>About This Repository</xsl:text>
                        </xsl:when>
                        <xsl:when test="not($page_title)">
                            <i18n:text>xmlui.dri2xhtml.METS-1.0.no-title</i18n:text>
                        </xsl:when>
                        <xsl:when test="$page_title = ''">
                            <i18n:text>xmlui.dri2xhtml.METS-1.0.no-title</i18n:text>
                        </xsl:when>
                        <xsl:otherwise>
                                <xsl:copy-of select="$page_title/node()" />
                        </xsl:otherwise>
                </xsl:choose>
            </title>

            <!-- Head metadata in item pages -->
            <xsl:if test="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='xhtml_head_item']">
                <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='xhtml_head_item']"
                              disable-output-escaping="yes"/>
            </xsl:if>

            <!-- Add all Google Scholar Metadata values -->
            <xsl:for-each select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[substring(@element, 1, 9) = 'citation_']">
                <meta name="{@element}" content="{.}"></meta>
            </xsl:for-each>

            <!-- Add MathJAX JS library to render scientific formulas-->
            <xsl:if test="confman:getProperty('webui.browse.render-scientific-formulas') = 'true'">
                <script type="text/x-mathjax-config">
                    MathJax.Hub.Config({
                      tex2jax: {
                        inlineMath: [['$','$'], ['\\(','\\)']],
                        ignoreClass: "detail-field-data|detailtable|exception"
                      },
                      TeX: {
                        Macros: {
                          AA: '{\\mathring A}'
                        }
                      }
                    });
                </script>
                <script type="text/javascript" src="//cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML">&#160;</script>
            </xsl:if>
            <!-- INICIO COMENTARIO PRODIGIO - HCB - 15.10.2015 - JS tema Prodigio -->
            <!-- HTML5 shim and Respond.js for IE8 support of HTML5 elements and media queries -->
            <!--[if lt IE 9]>
              <script src="https://oss.maxcdn.com/html5shiv/3.7.2/html5shiv.min.js"></script>
              <script src="https://oss.maxcdn.com/respond/1.4.2/respond.min.js"></script>
            <![endif]-->
            <!-- FIN COMENTARIO PRODIGIO -->            
        </head>
    </xsl:template>


    <!-- The header (distinct from the HTML head element) contains the title, subtitle, login box and various
        placeholders for header images -->
    <xsl:template name="buildHeader">
        <!-- INICIO COMENTARIO PRODIGIO - HCB - 06.10.2015 - Se modifica el Header
        <div id="ds-header-wrapper">
            <div id="ds-header" class="clearfix">
                <a id="ds-header-logo-link">
                    <xsl:attribute name="href">
                        <xsl:value-of
                                select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/>
                        <xsl:text>/</xsl:text>
                    </xsl:attribute>
                    <span id="ds-header-logo">&#160;</span>
                    <span id="ds-header-logo-text">
                       <i18n:text>xmlui.dri2xhtml.structural.head-subtitle</i18n:text>
                    </span>
                </a>
                <h1 class="pagetitle visuallyhidden">
                    <xsl:choose>
                        protection against an empty page title
                        <xsl:when test="not(/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='title'])">
                            <xsl:text> </xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:copy-of
                                    select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='title']/node()"/>
                        </xsl:otherwise>
                    </xsl:choose>

                </h1>

                <xsl:choose>
                    <xsl:when test="/dri:document/dri:meta/dri:userMeta/@authenticated = 'yes'">
                        <div id="ds-user-box">
                            <p>
                                <a>
                                    <xsl:attribute name="href">
                                        <xsl:value-of select="/dri:document/dri:meta/dri:userMeta/
                                        dri:metadata[@element='identifier' and @qualifier='url']"/>
                                    </xsl:attribute>
                                    <i18n:text>xmlui.dri2xhtml.structural.profile</i18n:text>
                                    <xsl:value-of select="/dri:document/dri:meta/dri:userMeta/
                                    dri:metadata[@element='identifier' and @qualifier='firstName']"/>
                                    <xsl:text> </xsl:text>
                                    <xsl:value-of select="/dri:document/dri:meta/dri:userMeta/
                                    dri:metadata[@element='identifier' and @qualifier='lastName']"/>
                                </a>
                                <xsl:text> | </xsl:text>
                                <a>
                                    <xsl:attribute name="href">
                                        <xsl:value-of select="/dri:document/dri:meta/dri:userMeta/
                                        dri:metadata[@element='identifier' and @qualifier='logoutURL']"/>
                                    </xsl:attribute>
                                    <i18n:text>xmlui.dri2xhtml.structural.logout</i18n:text>
                                </a>
                            </p>
                        </div>
                    </xsl:when>
                    <xsl:otherwise>
                        <div id="ds-user-box">
                            <p>
                                <a>
                                    <xsl:attribute name="href">
                                        <xsl:value-of select="/dri:document/dri:meta/dri:userMeta/
                                        dri:metadata[@element='identifier' and @qualifier='loginURL']"/>
                                    </xsl:attribute>
                                    <i18n:text>xmlui.dri2xhtml.structural.login</i18n:text>
                                </a>
                            </p>
                        </div>
                    </xsl:otherwise>
                </xsl:choose>
                
                <xsl:call-template name="languageSelection" />
                
            </div>
        </div>
        FIN COMENTARIO PRODIGIO -->
    </xsl:template>

    <!-- The header (distinct from the HTML head element) contains the title, subtitle, login box and various
        placeholders for header images -->
    <!-- INICIO COMENTARIO PRODIGIO - HCB - 06.10.2015 - Se elimina el bradcrumb original
    <xsl:template name="buildTrail">
        <div id="ds-trail-wrapper">
            <ul id="ds-trail">
                <xsl:choose>
                    <xsl:when test="starts-with($request-uri, 'page/about')">
                         <xsl:text>About This Repository</xsl:text>
                    </xsl:when>
                    <xsl:when test="count(/dri:document/dri:meta/dri:pageMeta/dri:trail) = 0">
                        <li class="ds-trail-link first-link">-</li>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="/dri:document/dri:meta/dri:pageMeta/dri:trail"/>
                    </xsl:otherwise>
                </xsl:choose>
            </ul>
        </div>
    
    </xsl:template>

    <xsl:template match="dri:trail">
        put an arrow between the parts of the trail
        <xsl:if test="position()>1">
            <li class="ds-trail-arrow">
                <xsl:text>&#8594;</xsl:text>
            </li>
        </xsl:if>
        <li>
            <xsl:attribute name="class">
                <xsl:text>ds-trail-link </xsl:text>
                <xsl:if test="position()=1">
                    <xsl:text>first-link </xsl:text>
                </xsl:if>
                <xsl:if test="position()=last()">
                    <xsl:text>last-link</xsl:text>
                </xsl:if>
            </xsl:attribute>
            Determine whether we are dealing with a link or plain text trail link
            <xsl:choose>
                <xsl:when test="./@target">
                    <a>
                        <xsl:attribute name="href">
                            <xsl:value-of select="./@target"/>
                        </xsl:attribute>
                        <xsl:apply-templates />
                    </a>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates />
                </xsl:otherwise>
            </xsl:choose>
        </li>
    </xsl:template>
    FIN COMENTARIO PRODIGIO -->
    <xsl:template name="cc-license">
        <xsl:param name="metadataURL"/>
        <xsl:variable name="externalMetadataURL">
            <xsl:text>cocoon:/</xsl:text>
            <xsl:value-of select="$metadataURL"/>
            <xsl:text>?sections=dmdSec,fileSec&amp;fileGrpTypes=THUMBNAIL</xsl:text>
        </xsl:variable>

        <xsl:variable name="ccLicenseName"
                      select="document($externalMetadataURL)//dim:field[@element='rights']"
                      />
        <xsl:variable name="ccLicenseUri"
                      select="document($externalMetadataURL)//dim:field[@element='rights'][@qualifier='uri']"
                      />
        <xsl:variable name="handleUri">
                    <xsl:for-each select="document($externalMetadataURL)//dim:field[@element='identifier' and @qualifier='uri']">
                        <a>
                            <xsl:attribute name="href">
                                <xsl:copy-of select="./node()"/>
                            </xsl:attribute>
                            <xsl:copy-of select="./node()"/>
                        </a>
                        <xsl:if test="count(following-sibling::dim:field[@element='identifier' and @qualifier='uri']) != 0">
                            <xsl:text>, </xsl:text>
                        </xsl:if>
                </xsl:for-each>
        </xsl:variable>

   <xsl:if test="$ccLicenseName and $ccLicenseUri and contains($ccLicenseUri, 'creativecommons')">
        <div about="{$handleUri}" class="clearfix">
            <xsl:attribute name="style">
                <xsl:text>margin:0em 2em 0em 2em; padding-bottom:0em;</xsl:text>
            </xsl:attribute>
            <a rel="license"
                href="{$ccLicenseUri}"
                alt="{$ccLicenseName}"
                title="{$ccLicenseName}"
                >
                <xsl:call-template name="cc-logo">
                    <xsl:with-param name="ccLicenseName" select="$ccLicenseName"/>
                    <xsl:with-param name="ccLicenseUri" select="$ccLicenseUri"/>
                </xsl:call-template>
            </a>
            <span>
                <xsl:attribute name="style">
                    <xsl:text>vertical-align:middle; text-indent:0 !important;</xsl:text>
                </xsl:attribute>
                <i18n:text>xmlui.dri2xhtml.METS-1.0.cc-license-text</i18n:text>
                <xsl:value-of select="$ccLicenseName"/>
            </span>
        </div>
        </xsl:if>
    </xsl:template>

    <xsl:template name="cc-logo">
        <xsl:param name="ccLicenseName"/>
        <xsl:param name="ccLicenseUri"/>
        <xsl:variable name="ccLogo">
             <xsl:choose>
                  <xsl:when test="starts-with($ccLicenseUri,
                                           'http://creativecommons.org/licenses/by/')">
                       <xsl:value-of select="'cc-by.png'" />
                  </xsl:when>
                  <xsl:when test="starts-with($ccLicenseUri,
                                           'http://creativecommons.org/licenses/by-sa/')">
                       <xsl:value-of select="'cc-by-sa.png'" />
                  </xsl:when>
                  <xsl:when test="starts-with($ccLicenseUri,
                                           'http://creativecommons.org/licenses/by-nd/')">
                       <xsl:value-of select="'cc-by-nd.png'" />
                  </xsl:when>
                  <xsl:when test="starts-with($ccLicenseUri,
                                           'http://creativecommons.org/licenses/by-nc/')">
                       <xsl:value-of select="'cc-by-nc.png'" />
                  </xsl:when>
                  <xsl:when test="starts-with($ccLicenseUri,
                                           'http://creativecommons.org/licenses/by-nc-sa/')">
                       <xsl:value-of select="'cc-by-nc-sa.png'" />
                  </xsl:when>
                  <xsl:when test="starts-with($ccLicenseUri,
                                           'http://creativecommons.org/licenses/by-nc-nd/')">
                       <xsl:value-of select="'cc-by-nc-nd.png'" />
                  </xsl:when>
                  <xsl:when test="starts-with($ccLicenseUri,
                                           'http://creativecommons.org/publicdomain/zero/')">
                       <xsl:value-of select="'cc-zero.png'" />
                  </xsl:when>
                  <xsl:when test="starts-with($ccLicenseUri,
                                           'http://creativecommons.org/publicdomain/mark/')">
                       <xsl:value-of select="'cc-mark.png'" />
                  </xsl:when>
                  <xsl:otherwise>
                       <xsl:value-of select="'cc-generic.png'" />
                  </xsl:otherwise>
             </xsl:choose>
        </xsl:variable>
        <xsl:variable name="ccLogoImgSrc">
            <xsl:value-of select="$theme-path"/>
            <xsl:text>/images/creativecommons/</xsl:text>
            <xsl:value-of select="$ccLogo"/>
        </xsl:variable>
        <img>
             <xsl:attribute name="src">
                <xsl:value-of select="$ccLogoImgSrc"/>
             </xsl:attribute>
             <xsl:attribute name="alt">
                 <xsl:value-of select="$ccLicenseName"/>
             </xsl:attribute>
             <xsl:attribute name="style">
                 <xsl:text>float:left; margin:0em 1em 0em 0em; border:none;</xsl:text>
             </xsl:attribute>
        </img>
    </xsl:template>

    <!-- Like the header, the footer contains various miscellaneous text, links, and image placeholders -->
    <xsl:template name="buildFooter">
        <!-- INICIO COMENTARIO PRODIGIO - HCB - 08.10.2015 - Modificación del footer
        <div id="ds-footer-wrapper">
            <div id="ds-footer">
                <div id="ds-footer-left">
                    <a href="http://www.dspace.org/" target="_blank">DSpace software</a> copyright&#160;&#169;&#160;2002-2015&#160; <a href="http://www.duraspace.org/" target="_blank">DuraSpace</a>
                </div>
                <div id="ds-footer-right">
                    <span class="theme-by">Theme by&#160;</span>
                    <a title="@mire NV" target="_blank" href="http://atmire.com" id="ds-footer-logo-link">
                    <span id="ds-footer-logo">&#160;</span>
                    </a>
                </div>
                <div id="ds-footer-links">
                    <a>
                        <xsl:attribute name="href">
                            <xsl:value-of
                                    select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/>
                            <xsl:text>/contact</xsl:text>
                        </xsl:attribute>
                        <i18n:text>xmlui.dri2xhtml.structural.contact-link</i18n:text>
                    </a>
                    <xsl:text> | </xsl:text>
                    <a>
                        <xsl:attribute name="href">
                            <xsl:value-of
                                    select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/>
                            <xsl:text>/feedback</xsl:text>
                        </xsl:attribute>
                        <i18n:text>xmlui.dri2xhtml.structural.feedback-link</i18n:text>
                    </a>
                </div>
        FIN COMENTARIO PRODIGIO -->
        
        <!-- INICIO COMENTARIO PRODIGIO - HCB - 08.10.2015 - Nuevo footer tema Prodigio. -->
        <footer>
            <div class="row">
              <div class="uLogo col-sm-6 col-md-2">
                <a href="">Universidad de magallanes</a>
              </div>

              <div class="col-sm-6 col-md-7">
                <h4>Gaia Antártica: Conocimiento y Cultura Antática</h4> 
                <address>
                    Universidad de Magallanes •  Avenida Bulnes 01855 • Punta Arenas • Chile<br/>
                    Teléfono: +56 61 207135 • Email: <a href="mailto:webmaster@example.com">walter.molina@umag.cl</a> 
                </address>
              </div>

              <div class="col-sm-6 col-md-3">
                <p class="pull-right"><a href="#">Back to top</a></p>
              </div>
            </div>
        </footer>        
        <!-- FIN COMENTARIO PRODIGIO -->
                <!-- INICIO COMENTARIO PRODIGIO - HCB - 08.10.2015 - Se deja intacto el link oculto al sitemap.
                    IMPORTANTE: Se debe crear la clase CSS "hidden" -->
                <!--Invisible link to HTML sitemap (for search engines) -->
                <a class="hidden">
                    <xsl:attribute name="href">
                        <xsl:value-of
                                select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/>
                        <xsl:text>/htmlmap</xsl:text>
                    </xsl:attribute>
                    <xsl:text>&#160;</xsl:text>
                </a>
        <!-- INICIO COMENTARIO PRODIGIO - HCB - 08.10.2015 - Se cierran las etiquetas div.
            </div>
        </div>
        FIN COMENTARIO PRODIGIO -->
        
    </xsl:template>


<!--
        The meta, body, options elements; the three top-level elements in the schema
-->




    <!--
        The template to handle the dri:body element. It simply creates the ds-body div and applies
        templates of the body's child elements (which consists entirely of dri:div tags).
    -->
    <xsl:template match="dri:body">
        <div id="ds-body">
            <xsl:if test="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='alert'][@qualifier='message']">
                <div id="ds-system-wide-alert">
                    <p>
                        <xsl:copy-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='alert'][@qualifier='message']/node()"/>
                    </p>
                </div>
            </xsl:if>

            <!-- Check for the custom pages -->
            <xsl:choose>
                <xsl:when test="starts-with($request-uri, 'page/about')">
                    <div>
                        <h1>About This Repository</h1>
                        <p>To add your own content to this page, edit webapps/xmlui/themes/Mirage/lib/xsl/core/page-structure.xsl and
                            add your own content to the title, trail, and body. If you wish to add additional pages, you
                            will need to create an additional xsl:when block and match the request-uri to whatever page
                            you are adding. Currently, static pages created through altering XSL are only available
                            under the URI prefix of page/.</p>
                    </div>
                </xsl:when>
                <!-- Otherwise use default handling of body -->
                <xsl:otherwise>
                    <!-- INICIO COMENTARIO PRODIGIO - HCB - 08.10.2015 - Aqui se incluye el código HTML para el body de la home. -->
                    <nav class="navbar-wrapper">
                        <nav class="navbar navbar-fixed-top">
                            <div class="navbar-header">
                              <button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target="#navbar" aria-expanded="false" aria-controls="navbar">
                                <span class="sr-only">Toggle navigation</span>
                                <span class="icon-bar"></span>
                                <span class="icon-bar"></span>
                                <span class="icon-bar"></span>
                              </button>
                               <a class="navbar-brand" href="index.html">
                                <img src="themes/Responsive/images/isotipo.png" alt="Ilustración a colores de la antártica"/>
                                  Gaia<span>Antártica</span> <small>Conocimiento y cultura de antártica</small>
                                </a>     
                            </div>
                            <div id="navbar" class="navbar-collapse collapse">
                              <ul class="nav navbar-nav">
                                <li><a href="#about">¿Quiénes somos?</a></li>
                                <li><a href="#ask">Preguntás frecuentes</a></li>
                                <li><a href="contact.html">Contacto</a></li>
                              </ul>
                              <ul class="lang list-inline">
                                <li class="active">Español</li>
                                <li><a href="#contact">English</a></li>
                              </ul>
                              <div class="uLogo visible-lg">
                                  <img src="themes/Responsive/images/uLogo.png" alt="Ilustración a colores de la antártica"/>
                              </div>
                            </div>
                        </nav>
                    </nav>

                    <!-- Main Carousel
                    ================================================== -->
                    <div id="mainCarousel" class="carousel slide" data-ride="carousel">
                        <div class="fixedSearch carousel-caption">
                          <form role="search">
                            <div id="mainSearch">
                              <div class="input-group">
                                  <input type="text" class="form-control input-lg" placeholder="Search"/>
                                  <div class="input-group-btn">
                                      <button type="submit" class="btn btn-lg">
                                          <span class="glyphicon glyphicon-search"></span>
                                      </button>
                                  </div>
                              </div>
                              <a href="" class="AdvanceSearch visible-lg">Busqueda avanzada</a>
                            </div>
                          </form> 
                        </div>
                          <!-- Indicators -->
                        <!-- <ol class="carousel-indicators">
                            <li data-target="#myCarousel" data-slide-to="0" class="active"></li>
                            <li data-target="#myCarousel" data-slide-to="1"></li>
                            <li data-target="#myCarousel" data-slide-to="2"></li>
                        </ol> -->
                        <div class="carousel-inner" role="listbox">
                          <div class="item active">
                            <img class="first-slide img-responsive" src="http://placehold.it/1200x500/" alt="First slide"/>
                          </div>
                          <div class="item">
                            <img class="second-slide img-responsive" src="http://placehold.it/1200x500/" alt="Second slide"/>
                          </div>
                          <div class="item">
                            <img class="third-slide img-responsive" src="http://placehold.it/1200x500/" alt="Third slide"/>
                          </div>
                        </div>
                <!--       <a class="left carousel-control" href="#myCarousel" role="button" data-slide="prev">
                        <span class="glyphicon glyphicon-chevron-left" aria-hidden="true"></span>
                        <span class="sr-only">Previous</span>
                      </a>
                      <a class="right carousel-control" href="#myCarousel" role="button" data-slide="next">
                        <span class="glyphicon glyphicon-chevron-right" aria-hidden="true"></span>
                        <span class="sr-only">Next</span>
                      </a> -->
                        <section id="breadcrums">
                          <ol class="breadcrumb"> 
                            Usted está aquí: 
                            <li><a href="">Inicio</a></li>
                             <li><a href="#">Library</a></li>
                            <li class="active">Data</li>
                          </ol>
                        </section>
                    </div><!-- /.carousel -->

                    <div class="container fill">
                                <div class="row row-offcanvas row-offcanvas-left">
                                        <aside class="col-xs-6 col-sm-3 sidebar-offcanvas" id="sidebar">
                                                <ul class="list-unstyled">
                                                        <h4>Navegar</h4>
                                                        <li><a href="#" class="active">Fecha de publicación</a></li>
                                                        <li><a href="#">Autores</a></li>
                                                        <li><a href="#">Materias</a></li>
                                                        <li><a href="#">Zonas Geográficas</a></li>
                                                        <li><a href="#">Tipo de documentos</a></li>
                                                </ul>

                                                <ul class="list-unstyled">
                                                        <h4>Alianzas</h4>
                                                        <li><a href="#">Instituto Chileno Antártico</a></li>
                                                        <li><a href="#">Centro de Estudios Hemisféricos y Polares</a></li>
                                                        <li><a href="#">Universidad Austral de Chile</a></li>
                                                        <li><a href="#">Universidad de Chile</a></li>
                                                        <li><a href="#">Universidad de Santiago</a></li>
                                                </ul>

                                                <ul class="list-unstyled">
                                                <h4>Sitio de interés</h4>
                                                <li><a href="#">Instituto Chileno Antártico</a></li>
                                                <li><a href="#">Universidad Austral de Chile</a></li>
                                                <li><a href="#">Universidad de Chile</a></li>
                                                <li><a href="#">Universidad de Santiago</a></li>
                                                </ul>

                                                <ul class="list-inline">
                                                <h4>Nuestras redes sociales</h4>
                                                <li><a class="facebook" href="#" alt="Facebook">Facebook</a></li>
                                                <li><a class="twitter" href="#">Twitter</a></li>
                                                <li><a class="youtube" href="#">Youtube</a></li>
                                                </ul>
                                          <div class="decoration">
                                          </div>
                                        </aside><!--/.sidebar-offcanvas-->

                                        <div class="col-xs-12 col-sm-9 mainContent">
                                                <p class="pull-left visible-xs">
                                                        <button type="button" class="btn sidebar-trigger" data-toggle="offcanvas"><span class="glyphicon glyphicon-menu-hamburger" aria-hidden="true"></span></button>
                                                </p>

                                                <section id="explore">
                                                        <h2>Explorar</h2>
                                                        <ul id="myTabs" class="nav nav-tabs" role="tablist">
                                                                <li role="presentation" class="active"><a href="#highlight" id="home-tab" role="tab" data-toggle="tab" aria-controls="highlight" aria-expanded="true">Destacado</a></li>
                                                                <li role="presentation" class=""><a href="#collections" role="tab" id="colections-tab" data-toggle="tab" aria-controls="colections" aria-expanded="false">Colecciones</a></li>
                                                        </ul>
                                                        <div id="myTabContent" class="tab-content">
                                                                <div role="tabpanel" class="tab-pane fade active in highlight" id="highlight" aria-labelledby="highlight-tab">
                                                                        <div class="row">
                                                                                <div class="books-zoom col-md-15 col-xs-6">
                                                                                  <a href="#">
                                                                                        <img src="http://placehold.it/140x180/" alt="..."/>
                                                                                        <span>Lorem ipsum dolor sit amet, consect...</span>
                                                                                  </a>
                                                                                </div>
                                                                                <div class="books-zoom col-md-15 col-xs-6">
                                                                                  <a href="#">
                                                                                        <img src="http://placehold.it/140x180/" alt="..."/>
                                                                                        <span>Lorem ipsum dolor sit amet, consect...</span>
                                                                                  </a>
                                                                                </div>                       
                                                                                <div class="books-zoom col-md-15 col-xs-6">
                                                                                  <a href="#">
                                                                                        <img src="http://placehold.it/140x180/" alt="..."/>
                                                                                        <span>Lorem ipsum dolor sit amet, consect...</span>
                                                                                  </a>
                                                                                </div>
                                                                                <div class="books-zoom col-md-15 col-xs-6">
                                                                                  <a href="#">
                                                                                        <img src="http://placehold.it/140x180/" alt="..."/>
                                                                                        <span>Lorem ipsum dolor sit amet, consect...</span>
                                                                                  </a>
                                                                                </div>
                                                                                <div class="books-zoom col-md-15 col-xs-6">
                                                                                  <a href="#">
                                                                                        <img src="http://placehold.it/140x180/" alt="..."/>
                                                                                        <span>Lorem ipsum dolor sit amet, consect...</span>
                                                                                  </a>
                                                                                </div>
                                                                        </div>
                                                                </div>

                                                                <div role="tabpanel" class="tab-pane fade" id="collections" aria-labelledby="collections-tab">
                                                                    <div class="row">
                                                                                <div class="col-sm-6 col-md-3">
                                                                                  <div class="thumbnail">
                                                                                        <img src="http://placehold.it/260x200/" alt="..."/>
                                                                                        <div class="caption">
                                                                                          <h3><a href="">Thumbnail label</a></h3>
                                                                                          <p>Colección: <a href="">umag</a></p>
                                                                                          <p class="viewed">1500 Visitas</p>
                                                                                        </div>
                                                                                  </div>
                                                                                </div>
                                                                                <div class="col-sm-6 col-md-3">
                                                                                  <div class="thumbnail">
                                                                                        <img src="http://placehold.it/260x200/" alt="..."/>
                                                                                        <div class="caption">
                                                                                          <h3><a href="">Thumbnail label</a></h3>
                                                                                          <p>Colección: <a href="">umag</a></p>
                                                                                          <p class="viewed">1500 Visitas</p>
                                                                                        </div>
                                                                                  </div>
                                                                                </div>
                                                                                <div class="col-sm-6 col-md-3">
                                                                                  <div class="thumbnail">
                                                                                        <img src="http://placehold.it/260x200/" alt="..."/>
                                                                                        <div class="caption">
                                                                                          <h3><a href="">Thumbnail label</a></h3>
                                                                                          <p>Colección: <a href="">umag</a></p>
                                                                                          <p class="viewed">1500 Visitas</p>
                                                                                        </div>
                                                                                  </div>
                                                                                </div>
                                                                                <div class="col-sm-6 col-md-3">
                                                                                  <div class="thumbnail">
                                                                                        <img src="http://placehold.it/260x200/" alt="..."/>
                                                                                        <div class="caption">
                                                                                          <h3><a href="">Thumbnail label</a></h3>
                                                                                          <p>Colección: <a href="">umag</a></p>
                                                                                          <p class="viewed">1500 Visitas</p>
                                                                                        </div>
                                                                                  </div>
                                                                                </div>                    
                                                                    </div>
                                                                </div>
                                                        </div>
                                                </section>
                                                <section id="topics">
                                                        <h2>Temas</h2>
                                                        <div class="row">
                                                                <div class="col-sm-6 col-md-4">
                                                                  <div class="thumbnail">
                                                                        <img src="http://placehold.it/354x236/" alt="..."/>
                                                                        <div class="caption">
                                                                          <h3><a href="collection.html">Link a la página de colecciones</a></h3>
                                                                          <p>Donec id elit non mi porta gravida at eget metus. Fusce dapibus, tellus ac cursus commodo, tortor mauris condimentum nibh, ut fermentum massa justo sit amet risus. Etiam porta sem malesuada magna mollis euismod. Donec sed odio dui.</p>
                                                                        </div>
                                                                  </div>
                                                                </div>   

                                                                <div class="col-sm-6 col-md-4">
                                                                  <div class="thumbnail">
                                                                        <img src="http://placehold.it/354x236/" alt="..."/>
                                                                        <div class="caption">
                                                                          <h3><a href="">Thumbnail label</a></h3>
                                                                          <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc id euismod magna. Cras fermentum est et nisl venenatis suscipit. Proin ultricies justo vel pellentesque commodo. Praesent in commodo urna. Phasellus lacus dui, venenatis in massa sed, congue consequat nisi. Phasellus mollis tempus diam, in sollicitudin sapien efficitur laoreet.</p>
                                                                        </div>
                                                                  </div>
                                                                </div>

                                                                <div class="col-sm-6 col-md-4">
                                                                  <div class="thumbnail">
                                                                        <img src="http://placehold.it/354x236/" alt="..."/>
                                                                        <div class="caption">
                                                                          <h3><a href="">Thumbnail label</a></h3>
                                                                          <p>Donec id elit non mi porta gravida at eget metus. Fusce dapibus, tellus ac cursus commodo, tortor mauris condimentum nibh, ut fermentum massa justo sit amet risus. Etiam porta sem malesuada magna mollis euismod. Donec sed odio dui.</p>
                                                                        </div>
                                                                  </div>
                                                                </div>
                                                                <div class="col-sm-6 col-md-4">
                                                                  <div class="thumbnail">
                                                                        <img src="http://placehold.it/354x236/" alt="..."/>
                                                                        <div class="caption">
                                                                          <h3><a href="">Thumbnail label</a></h3>
                                                                          <p>Donec id elit non mi porta gravida at eget metus. Fusce dapibus, tellus ac cursus commodo, tortor mauris condimentum nibh, ut fermentum massa justo sit amet risus. Etiam porta sem malesuada magna mollis euismod. Donec sed odio dui.</p>
                                                                        </div>
                                                                  </div>
                                                                </div>   

                                                                <div class="col-sm-6 col-md-4">
                                                                  <div class="thumbnail">
                                                                        <img src="http://placehold.it/354x236/" alt="..."/>
                                                                        <div class="caption">
                                                                          <h3><a href="">Thumbnail label</a></h3>
                                                                          <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc id euismod magna. Cras fermentum est et nisl venenatis suscipit. Proin ultricies justo vel pellentesque commodo. Praesent in commodo urna. Phasellus lacus dui, venenatis in massa sed, congue consequat nisi. Phasellus mollis tempus diam, in sollicitudin sapien efficitur laoreet.</p>
                                                                        </div>
                                                                  </div>
                                                                </div>

                                                                <div class="col-sm-6 col-md-4">
                                                                  <div class="thumbnail">
                                                                        <img src="http://placehold.it/354x236/" alt="..."/>
                                                                        <div class="caption">
                                                                          <h3><a href="">Thumbnail label</a></h3>
                                                                          <p>Donec id elit non mi porta gravida at eget metus. Fusce dapibus, tellus ac cursus commodo, tortor mauris condimentum nibh, ut fermentum massa justo sit amet risus. Etiam porta sem malesuada magna mollis euismod. Donec sed odio dui.</p>
                                                                        </div>
                                                                  </div>
                                                                </div>

                                                                <div class="col-sm-6 col-md-4">
                                                                  <div class="thumbnail">
                                                                        <img src="http://placehold.it/354x236/" alt="..."/>
                                                                        <div class="caption">
                                                                          <h3><a href="">Thumbnail label</a></h3>
                                                                          <p>Donec id elit non mi porta gravida at eget metus. Fusce dapibus, tellus ac cursus commodo, tortor mauris condimentum nibh, ut fermentum massa justo sit amet risus. Etiam porta sem malesuada magna mollis euismod. Donec sed odio dui.</p>
                                                                        </div>
                                                                  </div>
                                                                </div>

                                                                <div class="col-sm-6 col-md-4">
                                                                  <div class="thumbnail">
                                                                        <img src="http://placehold.it/354x236/" alt="..."/>
                                                                        <div class="caption">
                                                                          <h3><a href="">Thumbnail label</a></h3>
                                                                          <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc id euismod magna. Cras fermentum est et nisl venenatis suscipit. Proin ultricies justo vel pellentesque commodo. Praesent in commodo urna. Phasellus lacus dui, venenatis in massa sed, congue consequat nisi. Phasellus mollis tempus diam, in sollicitudin sapien efficitur laoreet.</p>
                                                                        </div>
                                                                  </div>
                                                                </div>
                                                        </div><!--/row-->
                                                </section>

                                                <section class="sliderFeatured">
                                                        <h2>Últimos enviós</h2>
                                                        <div id="featured" class="carousel slide">
                                                                <div class="carousel-inner">
                                                                        <div class="item active">
                                                                                <div class="row">
                                                                                        <div class="col-sm-6 col-md-3">
                                                                                                <div class="thumbnail">
                                                                                                  <img src="http://placehold.it/110x160/" alt="Slide11"/>
                                                                                                  <div class="caption">
                                                                                                        <h3><a href="">Product label</a></h3>
                                                                                                  </div>
                                                                                                </div>        
                                                                                        </div>
                                                                                        <div class="col-sm-6 col-md-3">
                                                                                                <div class="thumbnail">
                                                                                                  <img src="http://placehold.it/110x160/" alt="Slide21"/>
                                                                                                  <div class="caption">
                                                                                                        <h3><a href="">Product label</a></h3>
                                                                                                  </div>
                                                                                                </div>        
                                                                                        </div>
                                                                                        <div class="col-sm-6 col-md-3">
                                                                                                <div class="thumbnail">
                                                                                                  <img src="http://placehold.it/110x160/" alt="Slide21"/>
                                                                                                  <div class="caption">
                                                                                                        <h3><a href="">Product label</a></h3>
                                                                                                  </div>
                                                                                                </div>        
                                                                                        </div>
                                                                                        <div class="col-sm-6 col-md-3">
                                                                                                <div class="thumbnail">
                                                                                                  <img src="http://placehold.it/110x160/" alt="Slide21"/>
                                                                                                  <div class="caption">
                                                                                                        <h3><a href="">Product label</a></h3>
                                                                                                  </div>
                                                                                                </div>        
                                                                                        </div>
                                                                                </div>
                                                                        </div>
                                                                        <div class="item">
                                                                                <div class="row">
                                                                                        <div class="col-sm-6 col-md-3">
                                                                                                <div class="thumbnail">
                                                                                                  <img src="http://placehold.it/110x160/" alt="Slide21"/>
                                                                                                  <div class="caption">
                                                                                                        <h3><a href="">Product label</a></h3>
                                                                                                  </div>
                                                                                                </div>        
                                                                                        </div>
                                                                                        <div class="col-sm-6 col-md-3">
                                                                                                <div class="thumbnail">
                                                                                                  <img src="http://placehold.it/110x160/" alt="Slide21"/>
                                                                                                  <div class="caption">
                                                                                                        <h3><a href="">Product label</a></h3>
                                                                                                  </div>
                                                                                                </div>        
                                                                                        </div>
                                                                                        <div class="col-sm-6 col-md-3">
                                                                                                <div class="thumbnail">
                                                                                                  <img src="http://placehold.it/110x160/" alt="Slide21"/>
                                                                                                  <div class="caption">
                                                                                                        <h3><a href="">Product label</a></h3>
                                                                                                  </div>
                                                                                                </div>        
                                                                                        </div>
                                                                                        <div class="col-sm-6 col-md-3">
                                                                                                <div class="thumbnail">
                                                                                                  <img src="http://placehold.it/110x160/" alt="Slide21"/>
                                                                                                  <div class="caption">
                                                                                                        <h3><a href="">Product label</a></h3>
                                                                                                  </div>
                                                                                                </div>        
                                                                                        </div>
                                                                                </div>
                                                                        </div>
                                                                        <div class="item">
                                                                                <div class="row">
                                                                                        <div class="col-sm-6 col-md-3">
                                                                                                <div class="thumbnail">
                                                                                                  <img src="http://placehold.it/110x160/" alt="Slide31"/>
                                                                                                  <div class="caption">
                                                                                                        <h3><a href="">Product label</a></h3>
                                                                                                  </div>
                                                                                                </div>        
                                                                                        </div>
                                                                                        <div class="col-sm-6 col-md-3">
                                                                                                <div class="thumbnail">
                                                                                                  <img src="http://placehold.it/110x160/" alt="Slide21"/>
                                                                                                  <div class="caption">
                                                                                                        <h3><a href="">Product label</a></h3>
                                                                                                  </div>
                                                                                                </div>        
                                                                                        </div>
                                                                                        <div class="col-sm-6 col-md-3">
                                                                                                <div class="thumbnail">
                                                                                                  <img src="http://placehold.it/110x160/" alt="Slide21"/>
                                                                                                  <div class="caption">
                                                                                                        <h3><a href="">Product label</a></h3>
                                                                                                  </div>
                                                                                                </div>        
                                                                                        </div>
                                                                                        <div class="col-sm-6 col-md-3">
                                                                                                <div class="thumbnail">
                                                                                                  <img src="http://placehold.it/110x160/" alt="Slide21"/>
                                                                                                  <div class="caption">
                                                                                                        <h3><a href="">Product label</a></h3>
                                                                                                  </div>
                                                                                                </div>        
                                                                                        </div>
                                                                                </div>
                                                                        </div>
                                                                </div>
                                                          <div class="carousel-controls">
                                                                <a class="left carousel-control" href="#featured" data-slide="prev"><span class="glyphicon glyphicon-chevron-left"></span></a>
                                                                <a class="right carousel-control" href="#featured" data-slide="next"><span class="glyphicon glyphicon-chevron-right"></span></a>
                                                          </div>

                                                                <ol class="carousel-indicators">
                                                                        <li data-target="#featured" data-slide-to="0" class="active"></li>
                                                                        <li data-target="#featured" data-slide-to="1" class=""></li>
                                                                        <li data-target="#featured" data-slide-to="2" class=""></li>
                                                                </ol>                
                                                        </div><!-- End Carousel --> 
                                                </section>          
                                        </div><!--/.col-xs-12.col-sm-9-->
                                </div><!--/row-->
                        </div><!-- /.container -->
                    <!-- FIN COMENTARIO PRODIGIO -->
                    
                    <!-- INICIO COMENTARIO PRODIGIO - HCB - 08.10.2015 - Se elimina el navegador por comunidades en el body de la home. -->
                    <xsl:apply-templates select="*[not(@n='comunity-browser')]" />
                     <!-- FIN COMENTARIO PRODIGIO -->
                </xsl:otherwise>
            </xsl:choose>

        </div>
    </xsl:template>


    <!-- Currently the dri:meta element is not parsed directly. Instead, parts of it are referenced from inside
        other elements (like reference). The blank template below ends the execution of the meta branch -->
    <xsl:template match="dri:meta">
    </xsl:template>

    <!-- Meta's children: userMeta, pageMeta, objectMeta and repositoryMeta may or may not have templates of
        their own. This depends on the meta template implementation, which currently does not go this deep.
    <xsl:template match="dri:userMeta" />
    <xsl:template match="dri:pageMeta" />
    <xsl:template match="dri:objectMeta" />
    <xsl:template match="dri:repositoryMeta" />
    -->

    <xsl:template name="addJavascript">
        <xsl:variable name="jqueryVersion">
            <xsl:text>1.6.2</xsl:text>
        </xsl:variable>

        <script type="text/javascript" src="{concat($scheme, 'ajax.googleapis.com/ajax/libs/jquery/', $jqueryVersion ,'/jquery.min.js')}">&#160;</script>

        <xsl:variable name="localJQuerySrc">
                <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/>
            <xsl:text>/static/js/jquery-</xsl:text>
            <xsl:value-of select="$jqueryVersion"/>
            <xsl:text>.min.js</xsl:text>
        </xsl:variable>

        <script type="text/javascript">
            <xsl:text disable-output-escaping="yes">!window.jQuery &amp;&amp; document.write('&lt;script type="text/javascript" src="</xsl:text><xsl:value-of
                select="$localJQuerySrc"/><xsl:text disable-output-escaping="yes">"&gt;&#160;&lt;\/script&gt;')</xsl:text>
        </script>



        <!-- Add theme javascipt  -->
        <xsl:for-each select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='javascript'][@qualifier='url']">
            <script type="text/javascript">
                <xsl:attribute name="src">
                    <xsl:value-of select="."/>
                </xsl:attribute>&#160;</script>
        </xsl:for-each>

        <xsl:for-each select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='javascript'][not(@qualifier)]">
            <script type="text/javascript">
                <xsl:attribute name="src">
                    <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/>
                    <xsl:text>/themes/</xsl:text>
                    <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='theme'][@qualifier='path']"/>
                    <xsl:text>/</xsl:text>
                    <xsl:value-of select="."/>
                </xsl:attribute>&#160;</script>
        </xsl:for-each>

        <!-- add "shared" javascript from static, path is relative to webapp root -->
        <xsl:for-each select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='javascript'][@qualifier='static']">
            <!--This is a dirty way of keeping the scriptaculous stuff from choice-support
            out of our theme without modifying the administrative and submission sitemaps.
            This is obviously not ideal, but adding those scripts in those sitemaps is far
            from ideal as well-->
            <xsl:choose>
                <xsl:when test="text() = 'static/js/choice-support.js'">
                    <script type="text/javascript">
                        <xsl:attribute name="src">
                            <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/>
                            <xsl:text>/themes/</xsl:text>
                            <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='theme'][@qualifier='path']"/>
                            <xsl:text>/lib/js/choice-support.js</xsl:text>
                        </xsl:attribute>&#160;</script>
                </xsl:when>
                <xsl:when test="not(starts-with(text(), 'static/js/scriptaculous'))">
                    <script type="text/javascript">
                        <xsl:attribute name="src">
                            <xsl:value-of
                                    select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/>
                            <xsl:text>/</xsl:text>
                            <xsl:value-of select="."/>
                        </xsl:attribute>&#160;</script>
                </xsl:when>
            </xsl:choose>
        </xsl:for-each>

        <!-- add setup JS code if this is a choices lookup page -->
        <xsl:if test="dri:body/dri:div[@n='lookup']">
          <xsl:call-template name="choiceLookupPopUpSetup"/>
        </xsl:if>

        <!--PNG Fix for IE6-->
        <xsl:text disable-output-escaping="yes">&lt;!--[if lt IE 7 ]&gt;</xsl:text>
        <script type="text/javascript">
            <xsl:attribute name="src">
                <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/>
                <xsl:text>/themes/</xsl:text>
                <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='theme'][@qualifier='path']"/>
                <xsl:text>/lib/js/DD_belatedPNG_0.0.8a.js?v=1</xsl:text>
            </xsl:attribute>&#160;</script>
        <script type="text/javascript">
            <xsl:text>DD_belatedPNG.fix('#ds-header-logo');DD_belatedPNG.fix('#ds-footer-logo');$.each($('img[src$=png]'), function() {DD_belatedPNG.fixPng(this);});</xsl:text>
        </script>
        <xsl:text disable-output-escaping="yes" >&lt;![endif]--&gt;</xsl:text>


        <script type="text/javascript">
            runAfterJSImports.execute();
        </script>

        <!-- Add a google analytics script if the key is present -->
        <xsl:if test="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='google'][@qualifier='analytics']">
            <script type="text/javascript"><xsl:text>
                   var _gaq = _gaq || [];
                   _gaq.push(['_setAccount', '</xsl:text><xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='google'][@qualifier='analytics']"/><xsl:text>']);
                   _gaq.push(['_trackPageview']);

                   (function() {
                       var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
                       ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
                       var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
                   })();
           </xsl:text></script>
        </xsl:if>

        <!-- Add a contextpath to a JS variable -->
                <script type="text/javascript"><xsl:text>
                         if(typeof window.orcid === 'undefined'){
                            window.orcid={};
                          };
                        window.orcid.contextPath= '</xsl:text><xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='contextPath'][not(@qualifier)]"/><xsl:text>';</xsl:text>
                    <xsl:text>window.orcid.themePath= '</xsl:text><xsl:value-of select="$theme-path"/><xsl:text>';</xsl:text>
                </script>
        <!-- INICIO COMENTARIO PRODIGIO - HCB - 15.10.2015 - Se agrega JS tema Prodigio -->       
        <!-- Bootstrap core JavaScript
        ================================================== -->
        <!-- Placed at the end of the document so the pages load faster -->
        <script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.3/jquery.min.js"></script>
        <script type="text/javascript" src="/xmlui/themes/Responsive/lib/js/bootstrap.min.js"></script>

        <script type="text/javascript">
          $(document).ready(function() {
            // grab the initial top offset of the navigation 
              var stickyNavTop = $('.fixedSearch').offset().top;

              // our function that decides weather the navigation bar should have "fixed" css position or not.
              var stickyNav = function(){
                var scrollTop = $(window).scrollTop(); // our current vertical position from the top

                // if we've scrolled more than the navigation, change its position to fixed to stick to top,
                // otherwise change it back to relative
                if (scrollTop > stickyNavTop) { 
                    $('.fixedSearch').addClass('sticky');
                } else {
                    $('.fixedSearch').removeClass('sticky'); 
                }
                if (scrollTop > stickyNavTop) { 
                    $('.navbar').addClass('navbar-inverse');
                } else {
                    $('.navbar').removeClass('navbar-inverse'); 
                }
            };
            stickyNav();
            // and run it again every time you scroll
            $(window).scroll(function() {
              stickyNav();
            });
          });
        </script>
        <!-- IE10 viewport hack for Surface/desktop Windows 8 bug -->
        <script type="text/javascript" src="assets/js/ie10-viewport-bug-workaround.js"></script>
        <script type="text/javascript" src="/xmlui/themes/Responsive/lib/js/offcanvas.js"></script>        
        <!-- FIN COMENTARIO PRODIGIO -->

    </xsl:template>
    
    <!-- Display language selection if more than 1 language is supported (overides buggy dir2xhtml-alt). 
    Uses a page metadata curRequestURI which was introduced by in /xmlui/src/main/webapp/themes/Mirage/sitemap.xmap-->
    <xsl:template name="languageSelection">
        <xsl:variable name="curRequestURI">
            <xsl:value-of select="substring-after(/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='curRequestURI'],/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='request'][@qualifier='URI'])"/>
        </xsl:variable>
        <xsl:if test="count(/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='page'][@qualifier='supportedLocale']) &gt; 1">
            <div id="ds-language-selection">
                <xsl:for-each select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='page'][@qualifier='supportedLocale']">
                    <xsl:variable name="locale" select="."/>
                    <a>
                        <xsl:attribute name="href">
                            <xsl:value-of select="$curRequestURI"/>
                            <xsl:call-template name="getLanguageURL"/>
                            <xsl:value-of select="$locale"/>
                        </xsl:attribute>
                        <xsl:value-of select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='supportedLocale'][@qualifier=$locale]"/>
                    </a>
                </xsl:for-each>
            </div>
        </xsl:if>
    </xsl:template>
    <!-- Builds the Query String part of the language URL. If there allready is an excisting query string 
    like: ?filtertype=subject&filter_relational_operator=equals&filter=keyword1 it appends the locale parameter with the ampersand (&) symbol -->
    <xsl:template name="getLanguageURL">
        <xsl:variable name="queryString" select="/dri:document/dri:meta/dri:pageMeta/dri:metadata[@element='request'][@qualifier='queryString']"/>
        <xsl:choose>
            <!-- There allready is a query string so append it and the language argument -->
            <xsl:when test="$queryString != ''">
                <xsl:text>?</xsl:text>
                <xsl:choose>
                    <xsl:when test="contains($queryString, '&amp;locale-attribute')">
                        <xsl:value-of select="substring-before($queryString, '&amp;locale-attribute')"/>
                        <xsl:text>&amp;locale-attribute=</xsl:text>
                    </xsl:when>
                    <!-- the query string is only the locale-attribute so remove it to append the correct one -->
                    <xsl:when test="starts-with($queryString, 'locale-attribute')">
                        <xsl:text>locale-attribute=</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$queryString"/>
                        <xsl:text>&amp;locale-attribute=</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>?locale-attribute=</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
