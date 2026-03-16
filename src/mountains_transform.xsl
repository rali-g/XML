<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="html" encoding="UTF-8" indent="yes"/>

  <xsl:template match="/">
    <html lang="bg">
      <head>
        <title>Каталог на планините в България</title>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
        <link rel="stylesheet" type="text/css" href="style.css"/>
        <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"/>
        <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
        <style>
          #map { height: 460px; width: 100%; border-radius: 12px; }
        </style>
        <script type="text/javascript"><![CDATA[
          function sortTable(field) {
            var tbody = document.querySelector(".mountains-table tbody");
            if (!tbody) return;
            var rows = Array.prototype.slice.call(tbody.querySelectorAll("tr.mountain-row"));
            var pairs = rows.map(function(row) {
              var details = row.nextElementSibling;
              if (details && details.classList.contains("details-row")) return { row: row, details: details };
              return { row: row, details: null };
            });
            var numeric = (field === "height" || field === "area");
            var descending = numeric ? true : false;
            pairs.sort(function(a, b) {
              var av = a.row.getAttribute("data-" + field);
              var bv = b.row.getAttribute("data-" + field);
              if (av == null) av = "";
              if (bv == null) bv = "";
              if (numeric) {
                var na = Number(av);
                var nb = Number(bv);
                if (descending) return nb - na;
                return na - nb;
              }
              var cmp = String(av).localeCompare(String(bv), "bg", { sensitivity: "base" });
              if (descending) return -cmp;
              return cmp;
            });
            pairs.forEach(function(p) {
              tbody.appendChild(p.row);
              if (p.details) tbody.appendChild(p.details);
            });
            var renum = tbody.querySelectorAll("tr.mountain-row");
            for (var i = 0; i < renum.length; i++) {
              var td = renum[i].querySelector("td");
              if (td) td.textContent = String(i + 1);
            }
          }

          function initMap() {
            if (typeof L === "undefined") return;
            var el = document.getElementById("map");
            if (!el) return;
            var map = L.map("map").setView([42.7, 25.3], 7);
            L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
              maxZoom: 18,
              attribution: "© OpenStreetMap contributors"
            }).addTo(map);
            var rows = document.querySelectorAll("tr.mountain-row");
            var bounds = [];
            for (var i = 0; i < rows.length; i++) {
              var r = rows[i];
              var lat = parseFloat(r.getAttribute("data-lat"));
              var lng = parseFloat(r.getAttribute("data-lng"));
              if (!isFinite(lat) || !isFinite(lng)) continue;
              var name = r.getAttribute("data-name") || "";
              var peak = r.getAttribute("data-peak") || "";
              var height = r.getAttribute("data-height") || "";
              var region = r.getAttribute("data-region") || "";
              var type = r.getAttribute("data-type") || "";
              var marker = L.marker([lat, lng]).addTo(map);
              marker.bindPopup(
                "<strong>" + escapeHtml(name) + "</strong><br/>" +
                "Връх: " + escapeHtml(peak) + "<br/>" +
                "Височина: " + escapeHtml(height) + " м<br/>" +
                "Регион: " + escapeHtml(region) + "<br/>" +
                "Тип: " + escapeHtml(type)
              );
              bounds.push([lat, lng]);
            }
            if (bounds.length) map.fitBounds(bounds, { padding: [25, 25] });
          }

          function escapeHtml(s) {
            return String(s)
              .replace(/&/g, "&amp;")
              .replace(/</g, "&lt;")
              .replace(/>/g, "&gt;")
              .replace(/"/g, "&quot;")
              .replace(/'/g, "&#39;");
          }

          document.addEventListener("DOMContentLoaded", initMap);
        ]]></script>
      </head>
      <body>
        <div class="header">
          <h1>Каталог на планините в България</h1>
          <p class="subtitle">Пълен справочник на българските планини по региони и типове</p>
        </div>

        <div class="navigation">
          <h3>Сортиране по:</h3>
          <ul>
            <li><button type="button" onclick="sortTable('name')">Име</button></li>
            <li><button type="button" onclick="sortTable('height')">Височина</button></li>
            <li><button type="button" onclick="sortTable('area')">Площ</button></li>
            <li><button type="button" onclick="sortTable('type')">Тип</button></li>
            <li><button type="button" onclick="sortTable('region')">Регион</button></li>
          </ul>
        </div>

        <div class="content">
          <h2>Карта</h2>
          <div id="map"></div>
        </div>

        <div class="statistics">
          <h2>Статистика</h2>
          <p>Общо планини: <strong><xsl:value-of select="count(/catalog/mountains/mountain)"/></strong></p>
          <p>Региони: <strong><xsl:value-of select="count(/catalog/regions/region)"/></strong></p>
          <p>Младонагънати планини: <strong><xsl:value-of select="count(/catalog/mountains/mountain[@type_ref='t1'])"/></strong></p>
          <p>Старонагънати планини: <strong><xsl:value-of select="count(/catalog/mountains/mountain[@type_ref='t2'])"/></strong></p>
        </div>

        <div class="content">
          <h2>Планини</h2>
          <xsl:apply-templates select="/catalog/mountains"/>
        </div>

        <div class="regions-summary">
          <h2>Региони</h2>
          <xsl:apply-templates select="/catalog/regions" mode="summary"/>
        </div>

        <div class="footer">
          <p>© 2025 Каталог на планините в България | XML Технологии</p>
        </div>
      </body>
    </html>
  </xsl:template>

  <xsl:template match="mountains">
    <table class="mountains-table">
      <thead>
        <tr>
          <th>№</th>
          <th>Име</th>
          <th>Връх</th>
          <th>Височина (м)</th>
          <th>Площ (км²)</th>
          <th>Регион</th>
          <th>Тип</th>
          <th>Категория</th>
        </tr>
      </thead>
      <tbody>
        <xsl:apply-templates select="mountain"/>
      </tbody>
    </table>
  </xsl:template>

  <xsl:template match="mountain">
    <tr class="mountain-row"
        data-name="{name}"
        data-peak="{peak}"
        data-height="{max_height}"
        data-area="{area}"
        data-lat="{location/coordinates/latitude}"
        data-lng="{location/coordinates/longitude}"
        data-region="{/catalog/regions/region[@id=current()/@region_ref]/@name}"
        data-type="{/catalog/mountain_types/type[@id=current()/@type_ref]/@name}">

      <td><xsl:value-of select="position()"/></td>
      <td class="mountain-name"><strong><xsl:value-of select="name"/></strong></td>
      <td><xsl:value-of select="peak"/></td>
      <td class="number"><xsl:value-of select="max_height"/></td>
      <td class="number"><xsl:value-of select="area"/></td>
      <td>
        <xsl:variable name="rid" select="@region_ref"/>
        <xsl:value-of select="/catalog/regions/region[@id=$rid]/@name"/>
      </td>
      <td>
        <xsl:variable name="tid" select="@type_ref"/>
        <xsl:value-of select="/catalog/mountain_types/type[@id=$tid]/@name"/>
      </td>
      <td>
        <xsl:variable name="cid" select="@height_cat_ref"/>
        <xsl:value-of select="/catalog/height_categories/category[@id=$cid]/@name"/>
      </td>
    </tr>

    <tr class="details-row">
      <td colspan="8">
        <div class="mountain-details">
          <xsl:variable name="imgRaw">
            <xsl:choose>
              <xsl:when test="string-length(normalize-space(image/@src)) &gt; 0">
                <xsl:value-of select="normalize-space(image/@src)"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="normalize-space(image)"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>

          <xsl:variable name="imgFile">
            <xsl:choose>
              <xsl:when test="contains(string($imgRaw), '.')">
                <xsl:value-of select="string($imgRaw)"/>
              </xsl:when>
              <xsl:when test="string($imgRaw)='rila_img'">rila.jpg</xsl:when>
              <xsl:when test="string($imgRaw)='pirin_img'">pirin.jpg</xsl:when>
              <xsl:when test="string($imgRaw)='stara_planina_img'">stara_planina.jpg</xsl:when>
              <xsl:when test="string($imgRaw)='rodopi_img'">rodopi.jpg</xsl:when>
              <xsl:when test="string($imgRaw)='vitosha_img'">vitosha.jpg</xsl:when>
              <xsl:when test="string($imgRaw)='osogovo_img'">osogovo.jpg</xsl:when>
              <xsl:when test="string($imgRaw)='sredna_gora_img'">sredna_gora.jpg</xsl:when>
              <xsl:when test="string($imgRaw)='strandja_img'">strandja.jpg</xsl:when>
              <xsl:when test="string-length(string($imgRaw)) &gt; 0">
                <xsl:value-of select="concat(string($imgRaw), '.jpg')"/>
              </xsl:when>
            </xsl:choose>
          </xsl:variable>

          <xsl:if test="string-length(string($imgFile)) &gt; 0">
            <div class="mountain-image">
              <img>
                <xsl:attribute name="src">
                  <xsl:choose>
                    <xsl:when test="contains(string($imgFile), '/') or contains(string($imgFile), ':')">
                      <xsl:value-of select="string($imgFile)"/>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="concat('images/', string($imgFile))"/>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:attribute>
                <xsl:attribute name="data-fallback">
                  <xsl:if test="not(contains(string($imgFile), '/') or contains(string($imgFile), ':'))">
                    <xsl:value-of select="string($imgFile)"/>
                  </xsl:if>
                </xsl:attribute>
                <xsl:attribute name="onerror">this.onerror=null; if(this.getAttribute('data-fallback')) this.src=this.getAttribute('data-fallback');</xsl:attribute>
                <xsl:attribute name="alt"><xsl:value-of select="name"/></xsl:attribute>
                <xsl:attribute name="loading">lazy</xsl:attribute>
              </img>
            </div>
          </xsl:if>

          <p><strong>Геоложка епоха:</strong> <xsl:value-of select="geological_age"/></p>
          <p><strong>Скален състав:</strong> <xsl:value-of select="rock_type"/></p>
          <p><strong>Описание:</strong> <xsl:value-of select="description"/></p>
          <p><strong>Забележителности:</strong> <xsl:value-of select="attractions"/></p>
          <p><strong>Координати:</strong> <xsl:value-of select="location/coordinates/latitude"/>, <xsl:value-of select="location/coordinates/longitude"/></p>
        </div>
      </td>
    </tr>
  </xsl:template>

  <xsl:template match="regions" mode="summary">
    <div class="regions-list">
      <xsl:apply-templates select="region" mode="summary"/>
    </div>
  </xsl:template>

  <xsl:template match="region" mode="summary">
    <div class="region-item">
      <h3><xsl:value-of select="@name"/></h3>
      <p><xsl:value-of select="description"/></p>
      <p><strong>Планини в региона:</strong></p>
      <ul>
        <xsl:variable name="current_region_id" select="@id"/>
        <xsl:for-each select="/catalog/mountains/mountain[@region_ref=$current_region_id]">
          <li><xsl:value-of select="name"/> (<xsl:value-of select="max_height"/> м)</li>
        </xsl:for-each>
      </ul>
    </div>
  </xsl:template>

</xsl:stylesheet>
