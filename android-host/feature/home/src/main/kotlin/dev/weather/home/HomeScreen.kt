package dev.weather.home

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.testTagsAsResourceId
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.createSavedStateHandle
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import dev.weather.data.LocationRepository
import dev.weather.data.RecentCitiesStore
import dev.weather.model.Location

@Composable
public fun HomeRoute(repository: LocationRepository, recentStore: RecentCitiesStore, onOpen: (Location) -> Unit) {
    val viewModel: HomeViewModel = viewModel(factory = viewModelFactory {
        initializer { HomeViewModel(repository, createSavedStateHandle()) }
    })
    val state by viewModel.state.collectAsStateWithLifecycle()
    val recents by recentStore.cities.collectAsStateWithLifecycle()
    LaunchedEffect(viewModel) { viewModel.search(viewModel.state.value.query) }
    HomeScreen(state, recents, onQuery = { viewModel.search(it) },
        onRetry = { viewModel.search(state.query, immediately = true) }, onOpen = onOpen)
}

@Composable
private fun HomeScreen(state: SearchState, recent: List<Location>, onQuery: (String) -> Unit,
                       onRetry: () -> Unit, onOpen: (Location) -> Unit) {
    val focusManager = LocalFocusManager.current
    val keyboard = LocalSoftwareKeyboardController.current
    val openCity: (Location) -> Unit = { city ->
        focusManager.clearFocus()
        keyboard?.hide()
        onOpen(city)
    }
    MaterialTheme(colorScheme = lightColorScheme(primary = Color(0xff1e6261), surface = Color(0xfff5f5ef))) {
        Surface(modifier = Modifier.fillMaxSize().semantics { testTagsAsResourceId = true }) {
            LazyColumn(modifier = Modifier.fillMaxSize().safeDrawingPadding().imePadding(),
                contentPadding = PaddingValues(24.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
                item {
                    Text("天气手记", style = MaterialTheme.typography.headlineLarge, fontWeight = FontWeight.Bold)
                    Spacer(Modifier.height(8.dp))
                    Text("开发者：何送军", color = MaterialTheme.colorScheme.onSurfaceVariant)
                    Spacer(Modifier.height(8.dp))
                    Text("从一座城市，了解今天。", color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                item {
                    OutlinedTextField(value = state.query, onValueChange = onQuery,
                        label = { Text("搜索城市") }, placeholder = { Text("例如：上海、北京、Tokyo") },
                        singleLine = true, modifier = Modifier.fillMaxWidth().testTag("citySearch"),
                        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
                        keyboardActions = KeyboardActions(onSearch = { onRetry() }))
                }
                if (state.loading) item { LinearProgressIndicator(Modifier.fillMaxWidth()) }
                if (state.error != null) item {
                    Text(state.error, color = MaterialTheme.colorScheme.error)
                    TextButton(onClick = onRetry) { Text("重试") }
                }
                if (state.results.isNotEmpty()) {
                    item { Text("搜索结果", style = MaterialTheme.typography.titleMedium) }
                    items(state.results, key = { "result-${it.id}" }) { CityCard(it, openCity) }
                } else if (state.searched) item { Text("未找到城市，请尝试完整名称或英文名称。") }
                if (state.query.trim().length < 2) {
                    item { Text(if (recent.isEmpty()) "输入至少两个字符开始搜索" else "最近查看", style = MaterialTheme.typography.titleMedium) }
                    items(recent, key = { "recent-${it.id}" }) { CityCard(it, openCity) }
                }
                item {
                    Spacer(Modifier.height(24.dp))
                    Text("地点与天气数据来自 Open-Meteo · CC BY 4.0", style = MaterialTheme.typography.bodySmall)
                }
            }
        }
    }
}

@Composable
private fun CityCard(location: Location, onOpen: (Location) -> Unit) {
    Card(onClick = { onOpen(location) }, modifier = Modifier.fillMaxWidth().testTag("city-${location.id}")) {
        Column(Modifier.padding(20.dp)) {
            Text(location.name, style = MaterialTheme.typography.titleLarge)
            Spacer(Modifier.height(6.dp))
            Text(location.subtitle, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}
