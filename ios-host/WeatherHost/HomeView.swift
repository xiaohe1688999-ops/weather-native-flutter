import SwiftUI
import WeatherCore

struct HomeView: View {
    @StateObject private var model = HomeModel()
    @State private var selected: City?
    @FocusState private var searchFocused: Bool
    private let teal = Color(red: 0.12, green: 0.38, blue: 0.38)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("天气手记").font(.largeTitle.bold())
                Text("开发者：何送军").foregroundStyle(.secondary)
                Text("从一座城市，了解今天。").foregroundStyle(.secondary)
                HStack {
                    Image(systemName: "magnifyingglass").foregroundStyle(teal)
                    TextField("搜索城市，例如上海、Tokyo", text: Binding(get: { model.query }, set: { model.search($0) }))
                        .focused($searchFocused)
                        .submitLabel(.search).onSubmit { model.search(model.query, immediately: true) }
                        .accessibilityIdentifier("citySearch")
                    if !model.query.isEmpty {
                        Button { model.search("") } label: { Image(systemName: "xmark.circle.fill") }
                            .accessibilityLabel("清空搜索")
                    }
                }.padding(16).background(.white, in: RoundedRectangle(cornerRadius: 16))
                if model.loading { ProgressView("正在搜索…") }
                if let error = model.error {
                    Text(error).foregroundStyle(.red)
                    Button("重试") { model.search(model.query, immediately: true) }
                }
                if !model.cities.isEmpty {
                    Text("搜索结果").font(.headline)
                    ForEach(model.cities) { city in cityButton(city) }
                } else if model.searched { Text("未找到城市，请尝试完整名称或英文名称。") }
                if model.query.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 {
                    Text(model.recent.isEmpty ? "输入至少两个字符开始搜索" : "最近查看").font(.headline)
                    ForEach(model.recent) { city in cityButton(city) }
                }
                Text("地点与天气数据来自 Open-Meteo · CC BY 4.0").font(.caption).foregroundStyle(.secondary).padding(.top, 24)
            }.padding(24).frame(maxWidth: 700, alignment: .leading).frame(maxWidth: .infinity)
        }
        .background(Color(red: 0.96, green: 0.96, blue: 0.94)).tint(teal)
        .fullScreenCover(item: $selected) { city in
            FlutterWeatherView(city: city, onLoaded: { model.record(city) }, onClose: { selected = nil })
                .ignoresSafeArea().interactiveDismissDisabled()
        }
    }

    private func cityButton(_ city: City) -> some View {
        Button {
            guard selected == nil else { return }
            searchFocused = false
            selected = city
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(city.name).font(.title3.bold()).foregroundStyle(.primary)
                    Text(city.subtitle).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(teal)
            }.padding(20).background(.white, in: RoundedRectangle(cornerRadius: 20))
        }.buttonStyle(.plain).accessibilityIdentifier("city-\(city.id)")
    }
}
