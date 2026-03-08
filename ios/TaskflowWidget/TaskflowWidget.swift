import SwiftUI
import WidgetKit

private let widgetGroupId = "group.com.example.taskflow"

struct TaskflowEntry: TimelineEntry {
  let date: Date
  let listName: String
  let summary: String
  let tasks: [String]
}

struct TaskflowProvider: TimelineProvider {
  func placeholder(in context: Context) -> TaskflowEntry {
    TaskflowEntry(
      date: Date(),
      listName: "My Tasks",
      summary: "2/5 done • 3 active",
      tasks: ["○ Prepare release notes", "✓ Confirm QA checklist", "○ Review PR #42"]
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (TaskflowEntry) -> Void) {
    completion(loadEntry())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<TaskflowEntry>) -> Void) {
    let entry = loadEntry()
    let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
    completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
  }

  private func loadEntry() -> TaskflowEntry {
    let data = UserDefaults(suiteName: widgetGroupId)
    let listName = data?.string(forKey: "widget_list_name") ?? "My Tasks"
    let total = data?.integer(forKey: "widget_total") ?? 0
    let done = data?.integer(forKey: "widget_done") ?? 0
    let active = data?.integer(forKey: "widget_active") ?? 0
    let tasksJson = data?.string(forKey: "widget_tasks_json") ?? "[]"
    let tasks: [String]
    if let payload = tasksJson.data(using: .utf8),
       let decoded = try? JSONDecoder().decode([String].self, from: payload) {
      tasks = decoded.isEmpty ? ["No tasks in this list"] : decoded
    } else {
      tasks = ["No tasks in this list"]
    }

    return TaskflowEntry(
      date: Date(),
      listName: listName,
      summary: "\(done)/\(total) done • \(active) active",
      tasks: tasks
    )
  }
}

struct TaskflowWidgetView: View {
  var entry: TaskflowProvider.Entry

  var body: some View {
    ZStack {
      LinearGradient(
        colors: [Color(red: 0.92, green: 0.97, blue: 0.95), Color(red: 1.0, green: 0.95, blue: 0.84)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )

      VStack(alignment: .leading, spacing: 8) {
        Text(entry.listName)
          .font(.headline)
          .foregroundColor(Color(red: 0.07, green: 0.17, blue: 0.12))
          .lineLimit(1)

        Text(entry.summary)
          .font(.caption)
          .foregroundColor(Color(red: 0.18, green: 0.30, blue: 0.24))
          .lineLimit(1)

        Spacer(minLength: 2)

        Text("Tasks")
          .font(.caption2)
          .foregroundColor(.gray)

        VStack(alignment: .leading, spacing: 4) {
          ForEach(Array(entry.tasks.prefix(5).enumerated()), id: \.offset) { _, task in
            Text(task)
              .font(.subheadline)
              .foregroundColor(Color(red: 0.07, green: 0.17, blue: 0.12))
              .lineLimit(1)
          }
        }
      }
      .padding(14)
    }
    .widgetURL(URL(string: "taskflow://open"))
  }
}

@main
struct TaskflowWidget: Widget {
  let kind: String = "TaskflowWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: TaskflowProvider()) { entry in
      TaskflowWidgetView(entry: entry)
    }
    .configurationDisplayName("Taskflow")
    .description("Track your active tasks and progress.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
