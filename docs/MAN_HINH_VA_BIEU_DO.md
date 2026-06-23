# Màn hình & Biểu đồ — PRM393 Lab2 (JournalAI / SCIENTIA)

Tài liệu liệt kê **từng màn hình**, **biểu đồ** hiển thị trên màn đó, **API OpenAlex** tương ứng và **ý nghĩa** dữ liệu.

- Base URL: `https://api.openalex.org`
- Dữ liệu analytics mặc định từ năm **2000** trở đi (`publication_year:2000–nay`)
- Overview global thêm lọc **influential**: `cited_by_count:>100`
- File service: `lib/services/openalex_service.dart`
- Widget chung nhiều chart: `lib/widgets/analytics_charts_panel.dart`

---

## 1. Cấu trúc điều hướng chính

| Tab / vùng | File màn hình | Có biểu đồ? |
|------------|---------------|-------------|
| Home | `home_tab_screen.dart` | Không (search + tile) |
| Overview | `overview_screen.dart` | Có (bộ đầy đủ) |
| Keywords | `keywords_tab_screen.dart` | Có (mini trend) |
| Journal | `journal_tab_screen.dart` | Không (danh sách bài) |
| About | `about_screen.dart` | Không |
| Explore (search) | `search_screen.dart` | Có (bộ đầy đủ theo topic) |

---

## 2. Bộ biểu đồ dùng chung (`AnalyticsChartsPanel`)

Dùng ở **Overview** (`OverviewDashboardCharts`) và **Explore** (`ExploreTopicCharts`).  
Phạm vi dữ liệu:

- **Overview**: snapshot global (`dashboard*` trong `PublicationProvider`)
- **Explore**: kết quả search topic (`yearlyTrendFromOpenAlex`, `topAuthorsOpenAlex`, …)

Có bộ lọc thời gian: **Năm nay** (theo tháng) / **5 năm** / **10 năm**.

| # | Tên chart (UI) | Widget | API OpenAlex | Ý nghĩa |
|---|----------------|--------|--------------|---------|
| 1 | **Year / Month** | `YearVolumeBarChart` | `GET /works?group_by=publication_year` hoặc nhiều lần `GET /works` với `filter=from_publication_date:…,to_publication_date:…` (theo tháng) | Số bài xuất bản theo **năm** hoặc **tháng** trong khoảng đã chọn. Tap cột năm → `YearDetailScreen`. |
| 2 | **Publication Trend** | `TrendChart` (line + overlay) | Volume: như #1. Overlay citations: `fetchCitationMetricsByYear` — quét `cited_by_count` theo từng năm | Đường chính = **khối lượng bài**; đường đứt = **tổng trích dẫn** (chuẩn hóa để so sánh hình dạng). Cho thấy xu hướng tăng/giảm và mối quan hệ volume–citations. |
| 3 | **Open Access** | `OpenAccessDonutChart` | Hai lần đếm: `GET /works?filter=…,open_access.is_oa:true` và `…:false` (`meta.count`) | Tỷ lệ bài **mở** vs **đóng** trong phạm vi. |
| 4 | **Topic** | `KeywordBarChart` | `GET /works?group_by=topics.id` (+ `search` hoặc filter năm) | Top **chủ đề nghiên cứu** (OpenAlex Topics) theo số bài. |
| 5 | **Institution** | `KeywordBarChart` | `GET /works?group_by=authorships.institutions.id` | Tổ chức có **nhiều bài nhất** trong phạm vi (đếm theo authorship). |
| 6 | **Type** | `KeywordBarChart` | `GET /works?group_by=type` | Phân bố loại tài liệu: article, review, book-chapter, … |
| 7 | **Publication Sources** | `JournalBarChart` | `GET /works?group_by=primary_location.source.id` | Top **tạp chí / nguồn xuất bản** theo số bài. |
| 8 | **Research Leaders** | `KeywordBarChart` | `GET /works?group_by=authorships.author.id` | Tác giả có **nhiều bài nhất** trong phạm vi (không phải citations). |
| 9 | **Citation Leaders** | `KeywordBarChart` | **Global**: `GET /authors?sort=cited_by_count:desc&filter=works_count:>5` (hoặc `cited_by_count:>100`). **Explore + có topic**: `GET /authors?filter=topics.id:T1\|T2&sort=cited_by_count:desc`. **Fallback**: gom từ `GET /works?search=…&sort=cited_by_count:desc` | Tác giả xếp theo **tổng trích dẫn** (career hoặc trong topic khớp). Chỉ hiện khi ≥ 2 tác giả. |
| 10 | **Institution Impact** | `KeywordBarChart` | `GET /institutions?sort=cited_by_count:desc&filter=topics.id:…` (topic) hoặc filter global | Tổ chức xếp theo **tổng trích dẫn** (career stats OpenAlex). |
| 11 | **Countries** | `KeywordBarChart` | `GET /works?group_by=authorships.countries` | Phân bố bài theo **quốc gia tác giả** trong phạm vi works. |
| 12 | **H-Index Leaders** | `KeywordBarChart` | `GET /authors?sort=summary_stats.h_index:desc&filter=topics.id:…` (chỉ khi có topic từ search) | **h-index** sự nghiệp (`summary_stats.h_index`) của tác giả thuộc topic khớp. Không dùng `search=` trên `/authors`. |
| 13 | **Productivity vs Impact** | `ProductivityScatterChart` | Cùng nguồn `/authors` (topic filter) hoặc gom từ `/works` | Trục X = **số bài** (`works_count` hoặc số bài trong sample); trục Y = **citations**. Tap điểm → `AuthorDetailScreen`. |
| 14 | **Research Domains** | `DomainDonutChart` | Dùng lại dữ liệu **Topic** (#4) | Donut phân bố % giữa các lĩnh vực top. Legend tap → `DomainDetailScreen`. |

**Ghi chú Explore:** Impact charts (#9–#13) load **sau** khi có top topics từ `group_by=topics.id`, tránh gọi `/authors?search=` (tìm theo **tên** author — sai với tìm chủ đề).

---

## 3. Chi tiết từng màn hình

### 3.1. `SplashScreen` — `splash_screen.dart`

| Biểu đồ | API | Ý nghĩa |
|---------|-----|---------|
| Không | — | Màn khởi động, load dashboard. |

---

### 3.2. `HomeTabScreen` — `home_tab_screen.dart`

| Thành phần | API (gián tiếp) | Ý nghĩa |
|------------|-----------------|---------|
| Ô search | `GET /works?search={query}` (khi bấm tìm) | Mở Explore với topic. |
| Research Landscape (tile) | Dùng `trendingAreas` đã load global | Shortcut tới domain / Overview. |
| Insight text | `yearlyTrendFromOpenAlex` | Mô tả xu hướng ngắn, **không** vẽ chart. |

---

### 3.3. `OverviewScreen` — `overview_screen.dart`

| Thành phần | API | Ý nghĩa |
|------------|-----|---------|
| KPI Publications + Growth badge | `fetchWorksTotalCount`, `fetchPublicationTrendByYear`, `fetchAverageCitation` | Tổng bài influential, YoY trong khoảng thời gian. |
| **Toàn bộ `AnalyticsChartsPanel`** | Xem mục 2 | Dashboard analytics global. |
| Tile điều hướng | — | Mở Growth, Citation Leaders, Research Leaders, Domains, … |

**Load:** `PublicationProvider.loadDefaultDashboard()` → `_loadAllOpenAlexMetrics(globalInfluential: true)`.

---

### 3.4. `SearchScreen` (Explore) — `search_screen.dart`

| Thành phần | API | Ý nghĩa |
|------------|-----|---------|
| Topic Snapshot card | `meta.count`, trend năm/tháng, `topJournalsOpenAlex` — tính client (`ResearchInsights.buildTopicSnapshotForRange`) | KPI nhanh: tổng bài, % tăng trưởng, peak year/month, momentum, top journal. |
| **`ExploreTopicCharts`** | Giống mục 2, scope = `search={topic}` trên `/works` | Toàn bộ analytics cho **chủ đề đang tìm**. |
| Danh sách Publications | `GET /works?search={topic}&page=n` (sort relevance) | Bài khớp từ khóa, 20/trang. |

---

### 3.5. `KeywordsTabScreen` — `keywords_tab_screen.dart`

| Biểu đồ | API | Ý nghĩa |
|---------|-----|---------|
| **Publication Growth** (mini) | `fetchPublicationTrendByYear` + `fetchCitationMetricsByYear` | Trend line thu nhỏ + overlay citations. |
| Tile hub | — | Link tới Keyword Overview, Domains, Leaders, Journals, Growth. |

---

### 3.6. `GrowthScreen` — `growth_screen.dart`

| Biểu đồ | API | Ý nghĩa |
|---------|-----|---------|
| **Publication Volume Over Time** | `dashboardYearlyTrendFromOpenAlex`, `dashboardCitationsByYearOpenAlex` | Trend + overlay; lọc All / 5Y / 10Y trên client. |
| KPI CAGR, Peak Year | Tính từ trend (`ResearchInsights.analyzeTrend`) | Tốc độ tăng trưởng trung bình, năm đỉnh. |
| **Growth by Top Domains** (thanh ngang) | `fetchTopicGrowthInsights` — so sánh volume đầu/cuối khoảng năm cho từng topic | Topic **đang tăng nhanh** (% thay đổi). |

---

### 3.7. `KeywordsOverviewScreen` — `keywords_overview_screen.dart`

| Biểu đồ | API | Ý nghĩa |
|---------|-----|---------|
| **Top Research Keywords** | `GET /works?group_by=topics.id` | Bar ngang top keywords. |
| **Fastest Growing Topics** | `fetchTopicGrowthInsights` | Thanh % tăng trưởng theo topic. |

---

### 3.8. `ResearchDomainsScreen` — `research_domains_screen.dart`

| Biểu đồ | API | Ý nghĩa |
|---------|-----|---------|
| **Domain Distribution** | `DomainDonutChart` ← `group_by=topics.id` | Donut % lĩnh vực. |
| Danh sách domain | Cùng nguồn | Tap → `DomainDetailScreen`. |

---

### 3.9. `ResearchLeadersScreen` — `research_leaders_screen.dart`

| Biểu đồ | API | Ý nghĩa |
|---------|-----|---------|
| Không (danh sách) | `group_by=authorships.author.id` | Top tác giả theo **số bài**, không phải chart. |

---

### 3.10. `CitationLeadersScreen` — `citation_leaders_screen.dart`

| Tab | API | Ý nghĩa |
|-----|-----|---------|
| Papers | `GET /works?sort=cited_by_count:desc` (`fetchTopPapers`) | Bài trích dẫn cao nhất. |
| Authors | `dashboardRankedAuthors` (số bài) hoặc citation list | Xếp hạng tác giả. |
| Journals | `group_by=primary_location.source.id` | Tạp chí nhiều bài / citations tùy tab. |

---

### 3.11. `JournalsAnalysisScreen` — `journals_analysis_screen.dart`

| Biểu đồ | API | Ý nghĩa |
|---------|-----|---------|
| **Top Journals by Publications** | `JournalBarChart` ← `group_by=primary_location.source.id` | Bar ngang số bài theo journal. |
| Tab Publishers | Cùng nguồn journals (hiển thị list) | Phân tích nguồn xuất bản. |

---

### 3.12. `JournalTabScreen` — `journal_tab_screen.dart`

| Biểu đồ | API | Ý nghĩa |
|---------|-----|---------|
| Không | `fetchTopPapers` hoặc `fetchSearchPage` | Chỉ `PublicationCard` list. |

---

### 3.13. `TopPapersScreen` / `TopAuthorsScreen` / `TopJournalsScreen`

| Màn | API | Ý nghĩa |
|-----|-----|---------|
| Top Papers | `fetchTopPapers` | Danh sách classic top cited papers. |
| Top Authors | `group_by=authorships.author.id` | Danh sách classic. |
| Top Journals | `group_by=primary_location.source.id` | Danh sách classic. |

---

### 3.14. `AuthorDetailScreen` — `author_detail_screen.dart`

| Biểu đồ | API | Ý nghĩa |
|---------|-----|---------|
| **Publication trend** | `GET /works?filter=authorships.author.id:{id}&group_by=publication_year` | Số bài của tác giả theo năm (có thể + `search` nếu đang Explore). |
| Top journals (list) | `group_by=primary_location.source.id` + filter author | Nơi tác giả publish nhiều nhất. |
| Stats card | `meta.count` từ works list | Tổng bài, insight growth. |

---

### 3.15. `JournalDetailScreen` — `journal_detail_screen.dart`

| Biểu đồ | API | Ý nghĩa |
|---------|-----|---------|
| **Publication trend** | `GET /works?filter=primary_location.source.id:{id}&group_by=publication_year` | Khối lượng bài theo năm trên journal đó. |
| Top authors (list) | `group_by=authorships.author.id` + filter source | Tác giả publish nhiều trên journal. |

---

### 3.16. `InstitutionDetailScreen` — `institution_detail_screen.dart`

| Biểu đồ | API | Ý nghĩa |
|---------|-----|---------|
| **Publication trend** | `GET /works?filter=authorships.institutions.id:{id}&group_by=publication_year` | Hoạt động publish của institution theo năm. |
| Top authors (list) | `group_by=authorships.author.id` + filter institution | Tác giả chủ lực của viện. |

---

### 3.17. `DomainDetailScreen` — `domain_detail_screen.dart`

| Biểu đồ | API | Ý nghĩa |
|---------|-----|---------|
| **Domain trend** | `GET /works?filter=topics.id:{id}&group_by=publication_year` | Xu hướng bài thuộc topic/domain. |
| Top authors / journals | `group_by` author + journal + filter `topics.id` | Hệ sinh thái trong domain. |
| (Có `DomainDonutChart` định nghĩa trong file — dùng ở màn Domains) | — | — |

---

### 3.18. `YearDetailScreen` — `year_detail_screen.dart`

| Biểu đồ | API | Ý nghĩa |
|---------|-----|---------|
| Không chart | `GET /works?filter=publication_year:{year}` | Bài trong năm (+ `search` nếu Explore). |
| Hot topics (chip) | `GET /works?filter=publication_year:{year}&group_by=topics.id` | Topic nổi trong năm đó. |

---

### 3.19. `DetailScreen` — `detail_screen.dart`

| Biểu đồ | API | Ý nghĩa |
|---------|-----|---------|
| Không | Singleton work / related: `fetchRelatedWorks` | Chi tiết 1 bài, abstract, authors, link đọc. |

---

### 3.20. `AboutScreen` — `about_screen.dart`

| Biểu đồ | API | Ý nghĩa |
|---------|-----|---------|
| Không | Lưu `api_key` qua `OpenAlexConfig` | Cấu hình API key, mô tả app. |

---

## 4. Bảng tra cứu API ↔ `OpenAlexService`

| Hàm service | Endpoint | Tham số chính |
|-------------|----------|----------------|
| `fetchSearchPage` | `/works` | `search`, `page` |
| `fetchWorksTotalCount` | `/works` | `search` / `filter`, `per-page=1` |
| `fetchPublicationTrendByYear` | `/works` | `group_by=publication_year` |
| `fetchPublicationTrendByMonth` | `/works` | `filter=from_publication_date` (12 request/năm) |
| `fetchCitationMetricsByYear` | `/works` | group_by năm + quét `select=cited_by_count` |
| `fetchWorksGroupedCounts` | `/works` | `group_by={author\|journal\|topics\|institution\|type\|countries}` |
| `fetchOpenAccessBreakdown` | `/works` | `filter=open_access.is_oa:true/false` |
| `fetchTopPapers` | `/works` | `sort=cited_by_count:desc` |
| `fetchTopAuthorsByCitations` | `/authors` | `sort=cited_by_count:desc`, `filter=topics.id` |
| `fetchTopInstitutionsByCitations` | `/institutions` | `sort=cited_by_count:desc` |
| `fetchTopAuthorsByHIndex` | `/authors` | `sort=summary_stats.h_index:desc` |
| `fetchAuthorImpactProfiles` | `/authors` hoặc gom `/works` | Scatter data |
| `fetchCountryDistribution` | `/works` | `group_by=authorships.countries` |
| `fetchTopicGrowthInsights` | `/works` | Nhiều `group_by=publication_year` theo topic |
| `fetchAuthorYearlyTrend` | `/works` | `filter=authorships.author.id` + group_by năm |
| `fetchSourceYearlyTrend` | `/works` | `filter=primary_location.source.id` |
| `fetchInstitutionYearlyTrend` | `/works` | `filter=authorships.institutions.id` |
| `fetchConceptYearlyTrend` | `/works` | `filter=topics.id` |

---

## 5. Biểu đồ mockup SCIENTIA — trạng thái app

| Loại mockup | Trong app? | Ghi chú |
|-------------|------------|---------|
| Trend line / area | Có | `TrendChart` |
| Volume bar (năm/tháng) | Có | `YearVolumeBarChart` |
| Top keywords / institutions / types | Có | `KeywordBarChart` |
| Top journals | Có | `JournalBarChart` |
| Open Access donut | Có | `OpenAccessDonutChart` |
| Domain donut | Có | `DomainDonutChart` |
| Citation leaders (authors/institutions) | Có | `/authors`, `/institutions` |
| H-index | Có | `/authors` + `summary_stats` |
| Scatter productivity vs impact | Có | `ProductivityScatterChart` |
| Countries bar | Có | `group_by=authorships.countries` |
| Emerging topics growth bars | Có | `GrowthScreen`, `KeywordsOverviewScreen` |
| World map / collaboration arcs | Chưa | OpenAlex không có API map |
| Journal quartile Q1–Q3 | Chưa | Không có field quartile |
| Sankey preprint→journal | Chưa | Cần heuristic, không có API sẵn |
| Funding bubble ($) | Chưa | Không có quy mô tài trợ theo năm |
| Author collaboration network | Chưa | Chỉ có `authorships` trên từng work |

---

## 6. Luồng load dữ liệu (tóm tắt)

```
Overview: loadDefaultDashboard()
  → Future.wait(metrics works + countries)
  → _loadImpactMetrics()  // authors/institutions/h-index/scatter
  → snapshot dashboard*

Explore: searchPublications(topic)
  → fetchSearchPage (list 20 bài)
  → _loadAllOpenAlexMetrics(search: topic)
  → _loadImpactMetrics() với topicIds từ top topics
```

---

*Tài liệu sinh từ codebase PRM393_Lab2 — cập nhật khi thêm màn hoặc chart mới.*
