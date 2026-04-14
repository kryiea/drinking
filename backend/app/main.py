import json
from html import escape
from typing import Optional

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse

from app.api.routes import admin, auth, drink_definitions, drink_logs, exports, goals, insights, profile, recommendations
from app.core.config import settings
from app.persistence.repository import SQLAlchemyRepository
from app.persistence.session import build_engine, init_database, make_session_factory, seed_database
from app.services.llm import OpenAICompatibleLLMService


def create_app(*, database_url: Optional[str] = None) -> FastAPI:
    app = FastAPI(title=settings.app_name, version=settings.app_version)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    engine = build_engine(database_url or settings.database_url, echo=settings.database_echo)
    session_factory = make_session_factory(engine)
    init_database(engine)
    with session_factory() as session:
        seed_database(session)
    app.state.engine = engine
    app.state.session_factory = session_factory

    app.include_router(auth.router, prefix=settings.api_prefix)
    app.include_router(profile.router, prefix=settings.api_prefix)
    app.include_router(goals.router, prefix=settings.api_prefix)
    app.include_router(drink_definitions.router, prefix=settings.api_prefix)
    app.include_router(drink_logs.router, prefix=settings.api_prefix)
    app.include_router(insights.router, prefix=settings.api_prefix)
    app.include_router(recommendations.router, prefix=settings.api_prefix)
    app.include_router(exports.router, prefix=settings.api_prefix)
    app.include_router(admin.router, prefix=settings.api_prefix)
    llm_service = OpenAICompatibleLLMService()

    @app.get("/healthz", tags=["system"])
    def healthz() -> dict[str, str]:
        return {"status": "ok", "service": settings.app_name}

    @app.get("/support", response_class=HTMLResponse, include_in_schema=False)
    def support_page() -> HTMLResponse:
        with app.state.session_factory() as session:
            repository = SQLAlchemyRepository(session)
            snapshot = repository.get_admin_snapshot()
            feedback_items = repository.list_feedback()[:8]
            llm_status = llm_service.status()

        services = [
            {
                "name": "database",
                "target": settings.database_url,
                "state": "ready",
                "state_label": "已就绪",
                "detail": "本地数据库已经加入主链路，可直接承担联调和回归验证。",
            },
            {
                "name": "redis",
                "target": settings.redis_url,
                "state": "configured" if settings.redis_url else "disabled",
                "state_label": "已配置" if settings.redis_url else "未启用",
                "detail": "缓存与异步任务入口已经预留；没有 Redis 也不会阻塞当前开发。",
            },
            {
                "name": "object-storage",
                "target": settings.object_storage_endpoint,
                "state": "configured" if settings.object_storage_endpoint else "disabled",
                "state_label": "已配置" if settings.object_storage_endpoint else "未启用",
                "detail": "导出文件和报表后续会落在对象存储兼容层。",
            },
        ]

        support_snapshot = {
            "admin": snapshot.model_dump(mode="json"),
            "llm": llm_status.model_dump(mode="json"),
            "services": [
                {
                    "name": service["name"],
                    "target": service["target"],
                    "state": service["state"],
                    "detail": service["detail"],
                }
                for service in services
            ],
            "recent_feedback": [item.model_dump(mode="json") for item in feedback_items],
        }

        feedback_markup = "".join(
            (
                "<li class=\"feedback-item\">"
                f"<div class=\"feedback-top\"><strong>{escape(item.category)}</strong>"
                f"<span class=\"state-badge badge-{escape(item.status)}\">{'待处理' if item.status == 'new' else '已查看'}</span></div>"
                f"<p>{escape(item.content)}</p>"
                "</li>"
            )
            for item in feedback_items
        ) or "<li class=\"feedback-item\"><p>当前没有反馈积压。</p></li>"

        rules_markup = "".join(
            f"<span class=\"tag\">{escape(rule)}</span>" for rule in snapshot.rule_toggles.enabled_rules
        )

        services_markup = "".join(
            (
                "<article class=\"service-card\">"
                f"<div class=\"service-top\"><strong>{escape(service['name'])}</strong>"
                f"<span class=\"state-badge badge-{escape(service['state'])}\">{escape(service['state_label'])}</span></div>"
                f"<p class=\"subtle\">{escape(service['detail'])}</p>"
                f"<code>{escape(service['target'] or '未配置')}</code>"
                "</article>"
            )
            for service in services
        )

        support_snapshot_json = escape(json.dumps(support_snapshot, ensure_ascii=False, indent=2))
        default_system_prompt = escape("你是饮知开发期的运营支持助手，请用简洁、专业、可执行的中文回答。")
        default_prompt = escape("请为“首页文字太多、需要更强层级”这条 UX 反馈给出 3 条可直接落地的开发建议。")

        html = f"""
        <!doctype html>
        <html lang="zh-Hans">
          <head>
            <meta charset="utf-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1" />
            <title>饮知 Support 平台</title>
            <style>
              :root {{
                color-scheme: light;
                --bg: #eef5f1;
                --panel: rgba(255, 255, 255, 0.76);
                --panel-strong: rgba(255, 255, 255, 0.92);
                --ink: #18231f;
                --muted: #63746c;
                --accent: #167c5e;
                --accent-soft: rgba(22, 124, 94, 0.12);
                --warn: #df8a2f;
                --critical: #cb5643;
                --line: rgba(22, 124, 94, 0.12);
              }}
              * {{ box-sizing: border-box; }}
              body {{
                margin: 0;
                font-family: "SF Pro Display", "PingFang SC", sans-serif;
                color: var(--ink);
                background:
                  radial-gradient(circle at top left, rgba(22,124,94,0.12), transparent 28%),
                  radial-gradient(circle at top right, rgba(135, 187, 172, 0.18), transparent 24%),
                  linear-gradient(180deg, #f8fbf9 0%, var(--bg) 100%);
              }}
              main {{
                max-width: 1240px;
                margin: 0 auto;
                padding: 34px 20px 56px;
              }}
              h1, h2, h3, p {{
                margin: 0;
              }}
              .hero {{
                display: grid;
                grid-template-columns: 1.15fr 0.85fr;
                gap: 16px;
                margin-bottom: 18px;
              }}
              .dashboard {{
                display: grid;
                grid-template-columns: repeat(2, minmax(0, 1fr));
                gap: 16px;
              }}
              .panel {{
                background: var(--panel);
                backdrop-filter: blur(28px);
                border: 1px solid var(--line);
                border-radius: 30px;
                padding: 24px;
                box-shadow: 0 18px 44px rgba(16, 24, 20, 0.08);
              }}
              .eyebrow {{
                display: inline-flex;
                align-items: center;
                gap: 8px;
                margin-bottom: 14px;
                font-size: 12px;
                text-transform: uppercase;
                letter-spacing: 0.08em;
                color: var(--accent);
              }}
              h1 {{
                font-size: 34px;
                line-height: 1.08;
                margin-bottom: 12px;
              }}
              h2 {{
                font-size: 24px;
                line-height: 1.15;
                margin-bottom: 10px;
              }}
              h3 {{
                font-size: 19px;
                margin-bottom: 12px;
              }}
              .subtle {{
                color: var(--muted);
                line-height: 1.65;
              }}
              .metric-grid {{
                display: grid;
                grid-template-columns: repeat(4, minmax(0, 1fr));
                gap: 12px;
                margin: 20px 0 16px;
              }}
              .metric {{
                padding: 18px;
                border-radius: 22px;
                background: rgba(255,255,255,0.74);
                border: 1px solid rgba(255,255,255,0.88);
              }}
              .metric span {{
                display: block;
                color: var(--muted);
                font-size: 13px;
              }}
              .metric strong {{
                display: block;
                font-size: 29px;
                line-height: 1;
                margin-top: 10px;
              }}
              .pill-row, .preset-row, .tag-row, .toolbar {{
                display: flex;
                flex-wrap: wrap;
                gap: 10px;
              }}
              .pill-row {{
                margin-top: 12px;
              }}
              .pill {{
                display: inline-flex;
                align-items: center;
                gap: 8px;
                padding: 9px 12px;
                border-radius: 999px;
                background: rgba(255,255,255,0.7);
                border: 1px solid rgba(255,255,255,0.88);
                color: var(--muted);
                font-size: 13px;
              }}
              .meta-grid {{
                display: grid;
                grid-template-columns: repeat(4, minmax(0, 1fr));
                gap: 12px;
                margin: 16px 0;
              }}
              .meta-item {{
                padding: 14px;
                border-radius: 20px;
                background: rgba(255,255,255,0.68);
                border: 1px solid rgba(255,255,255,0.88);
              }}
              .meta-item span {{
                display: block;
                color: var(--muted);
                font-size: 12px;
                margin-bottom: 8px;
              }}
              .meta-item strong {{
                display: block;
                font-size: 15px;
                line-height: 1.45;
                word-break: break-word;
              }}
              label {{
                display: block;
                font-size: 13px;
                font-weight: 600;
                color: var(--muted);
                margin: 14px 0 8px;
              }}
              textarea, input {{
                width: 100%;
                border-radius: 18px;
                border: 1px solid var(--line);
                padding: 13px 15px;
                font: inherit;
                color: var(--ink);
                background: var(--panel-strong);
              }}
              textarea {{
                min-height: 112px;
                resize: vertical;
              }}
              .toolbar {{
                align-items: center;
                justify-content: space-between;
                margin-top: 14px;
              }}
              .field-inline {{
                display: flex;
                align-items: center;
                gap: 8px;
                margin: 0;
                color: var(--muted);
              }}
              .field-inline input {{
                width: 92px;
                padding: 10px 12px;
                border-radius: 14px;
              }}
              button {{
                border: none;
                border-radius: 999px;
                padding: 12px 18px;
                font: inherit;
                font-weight: 600;
                cursor: pointer;
                transition: transform 120ms ease, opacity 120ms ease;
              }}
              button:hover {{
                transform: translateY(-1px);
              }}
              .primary-button {{
                background: var(--accent);
                color: white;
                box-shadow: 0 12px 28px rgba(22,124,94,0.18);
              }}
              .ghost-button {{
                background: rgba(255,255,255,0.7);
                color: var(--ink);
                border: 1px solid rgba(255,255,255,0.88);
              }}
              .result, .json-panel {{
                border-radius: 22px;
                padding: 16px;
                white-space: pre-wrap;
                line-height: 1.65;
              }}
              .result {{
                margin-top: 14px;
                background: rgba(22,124,94,0.08);
                min-height: 88px;
              }}
              .json-stack {{
                display: grid;
                gap: 12px;
              }}
              .json-panel {{
                background: rgba(16, 24, 20, 0.06);
                overflow: auto;
                font-family: "SF Mono", "Menlo", monospace;
                font-size: 12px;
                min-height: 200px;
              }}
              .service-grid {{
                display: grid;
                gap: 12px;
              }}
              .service-card {{
                padding: 16px;
                border-radius: 22px;
                background: rgba(255,255,255,0.64);
                border: 1px solid rgba(255,255,255,0.82);
              }}
              .service-top, .feedback-top {{
                display: flex;
                align-items: center;
                justify-content: space-between;
                gap: 12px;
                margin-bottom: 8px;
              }}
              .state-badge {{
                display: inline-flex;
                align-items: center;
                justify-content: center;
                padding: 6px 10px;
                border-radius: 999px;
                font-size: 12px;
                font-weight: 700;
              }}
              .badge-ready, .badge-reviewed {{
                color: var(--accent);
                background: rgba(22,124,94,0.12);
              }}
              .badge-configured {{
                color: var(--warn);
                background: rgba(223,138,47,0.14);
              }}
              .badge-disabled, .badge-new {{
                color: var(--critical);
                background: rgba(203,86,67,0.14);
              }}
              .tag-row {{
                margin: 12px 0 16px;
              }}
              .tag {{
                display: inline-flex;
                align-items: center;
                padding: 8px 12px;
                border-radius: 999px;
                background: rgba(22,124,94,0.10);
                color: var(--accent);
                font-size: 13px;
                font-weight: 600;
              }}
              .threshold-list, .feedback-list {{
                margin: 0;
                padding: 0;
                list-style: none;
                display: grid;
                gap: 12px;
              }}
              .threshold-list li, .feedback-item {{
                padding: 15px 16px;
                border-radius: 20px;
                background: rgba(255,255,255,0.64);
                border: 1px solid rgba(255,255,255,0.82);
              }}
              .feedback-item p {{
                margin-top: 8px;
                color: var(--muted);
                line-height: 1.6;
              }}
              code {{
                display: inline-block;
                margin-top: 10px;
                font-family: "SF Mono", "Menlo", monospace;
                font-size: 12px;
                padding: 4px 8px;
                border-radius: 10px;
                background: rgba(22,124,94,0.08);
                word-break: break-all;
              }}
              .section-head {{
                display: flex;
                align-items: baseline;
                justify-content: space-between;
                gap: 12px;
                margin-bottom: 12px;
              }}
              .section-head span {{
                color: var(--muted);
                font-size: 13px;
              }}
              @media (max-width: 980px) {{
                .hero, .dashboard, .metric-grid, .meta-grid {{
                  grid-template-columns: 1fr;
                }}
              }}
            </style>
          </head>
          <body>
            <main>
              <section class="hero">
                <article class="panel">
                  <div class="eyebrow">Yinzhi Support Console</div>
                  <h1>本地 support 平台已经变成开发控制台。</h1>
                  <p class="subtle">
                    这里同时承接品牌库规模、规则阈值、反馈流转和 LLM 联调，
                    让你在本机就能完成产品验证、支持页试跑和服务状态确认。
                  </p>
                  <div class="metric-grid">
                    <div class="metric"><span>饮品条目</span><strong>{snapshot.drink_count}</strong></div>
                    <div class="metric"><span>品牌数量</span><strong>{snapshot.brand_count}</strong></div>
                    <div class="metric"><span>待处理反馈</span><strong>{snapshot.pending_feedback}</strong></div>
                    <div class="metric"><span>LLM 状态</span><strong>{"已配置" if llm_status.configured else "未配置"}</strong></div>
                  </div>
                  <div class="pill-row">
                    <div class="pill">API 基址 <code>{escape(settings.support_base_url)}</code></div>
                    <div class="pill">快照接口 <code>/v1/admin/support</code></div>
                    <div class="pill">健康检查 <code>/healthz</code></div>
                  </div>
                </article>

                <article class="panel">
                  <div class="eyebrow">LLM Bridge</div>
                  <h2>直接试跑 OpenAI 兼容提示链路</h2>
                  <p class="subtle">
                    这里默认接 Kimi 兼容接口，也保留 system prompt 和 temperature 调试位，
                    方便后续切国内或国外的 OpenAI 兼容服务。
                  </p>

                  <div class="meta-grid">
                    <div class="meta-item"><span>Provider</span><strong id="llmProvider">{escape(llm_status.provider)}</strong></div>
                    <div class="meta-item"><span>Base URL</span><strong id="llmBaseURL">{escape(llm_status.base_url or "未配置")}</strong></div>
                    <div class="meta-item"><span>Model</span><strong id="llmModel">{escape(llm_status.model or "未配置")}</strong></div>
                    <div class="meta-item"><span>模式 / 延迟</span><strong id="llmMode">{'live' if llm_status.configured else 'fallback'} · --</strong></div>
                  </div>

                  <div class="preset-row">
                    <button class="ghost-button" type="button" onclick="applyPreset('ux')">首页 UX</button>
                    <button class="ghost-button" type="button" onclick="applyPreset('rules')">规则解释</button>
                    <button class="ghost-button" type="button" onclick="applyPreset('support')">Support 回复</button>
                  </div>

                  <label for="systemPrompt">System Prompt</label>
                  <textarea id="systemPrompt">{default_system_prompt}</textarea>

                  <label for="llmPrompt">User Prompt</label>
                  <textarea id="llmPrompt">{default_prompt}</textarea>

                  <div class="toolbar">
                    <label class="field-inline" for="temperature">
                      Temperature
                      <input id="temperature" type="number" min="0" max="1.5" step="0.1" value="0.4" />
                    </label>
                    <button class="primary-button" type="button" onclick="previewLLM()">运行 LLM Preview</button>
                  </div>

                  <div class="result" id="llmResult">结果会显示在这里，适合快速试运行首页建议、support 回复或规则解释。</div>
                </article>
              </section>

              <section class="dashboard">
                <article class="panel">
                  <div class="section-head">
                    <h3>运行态服务</h3>
                    <span>本机链路是否具备联调条件</span>
                  </div>
                  <div class="service-grid">{services_markup}</div>
                </article>

                <article class="panel">
                  <div class="section-head">
                    <h3>规则与阈值</h3>
                    <span>建议引擎当前打开的开关</span>
                  </div>
                  <div class="tag-row">{rules_markup}</div>
                  <ul class="threshold-list">
                    <li>咖啡因预警阈值 <strong>{snapshot.rule_toggles.caffeine_warning_ratio:.0%}</strong></li>
                    <li>糖分预警阈值 <strong>{snapshot.rule_toggles.sugar_warning_ratio:.0%}</strong></li>
                    <li>晚间咖啡因截止 <strong>{snapshot.rule_toggles.late_caffeine_hour}:00</strong></li>
                  </ul>
                </article>

                <article class="panel">
                  <div class="section-head">
                    <h3>最近反馈</h3>
                    <span>给开发者的 support 收口池</span>
                  </div>
                  <ul class="feedback-list">{feedback_markup}</ul>
                </article>

                <article class="panel">
                  <div class="section-head">
                    <h3>原始返回</h3>
                    <span id="lastRefresh">等待刷新</span>
                  </div>
                  <div class="toolbar">
                    <button class="ghost-button" type="button" onclick="refreshSupport()">刷新 Support Snapshot</button>
                  </div>
                  <div class="json-stack">
                    <pre class="json-panel" id="supportSnapshot">{support_snapshot_json}</pre>
                    <pre class="json-panel" id="llmRaw">等待一次 LLM Preview 请求。</pre>
                  </div>
                </article>
              </section>
            </main>
            <script>
              const PRESETS = {{
                ux: {{
                  system: '你是饮知的 iOS 产品设计搭档，请给出偏可执行、偏界面层级的建议。',
                  prompt: '请针对“首页首屏文字太多、决策层级不够清楚”给出 3 条具体到组件和排版的优化建议。',
                  temperature: '0.4'
                }},
                rules: {{
                  system: '你是饮知的健康建议设计助手，请把规则、阈值和输出解释为可执行语言。',
                  prompt: '请把“糖分达到阈值 80% 时触发预警”的规则改写成适合首页卡片展示的一句话文案。',
                  temperature: '0.3'
                }},
                support: {{
                  system: '你是饮知的 support 平台助手，请用简洁、礼貌、专业的中文生成开发者支持回复。',
                  prompt: '用户反馈说“品牌筛选有了，但首页还是不够轻”，请写一条开发者内部 follow-up 回复。',
                  temperature: '0.5'
                }}
              }};

              function applyPreset(key) {{
                const preset = PRESETS[key];
                if (!preset) {{
                  return;
                }}
                document.getElementById('systemPrompt').value = preset.system;
                document.getElementById('llmPrompt').value = preset.prompt;
                document.getElementById('temperature').value = preset.temperature;
              }}

              async function previewLLM() {{
                const prompt = document.getElementById('llmPrompt').value.trim();
                const systemPrompt = document.getElementById('systemPrompt').value.trim();
                const temperatureText = document.getElementById('temperature').value.trim();
                const result = document.getElementById('llmResult');
                const llmRaw = document.getElementById('llmRaw');

                if (!prompt) {{
                  result.textContent = '请先输入 prompt。';
                  return;
                }}

                const payload = {{
                  prompt,
                  system_prompt: systemPrompt || undefined
                }};
                const temperature = Number(temperatureText);
                if (!Number.isNaN(temperature)) {{
                  payload.temperature = temperature;
                }}

                result.textContent = '请求中...';
                llmRaw.textContent = '请求中...';

                const startedAt = performance.now();
                const response = await fetch('/v1/admin/llm-preview', {{
                  method: 'POST',
                  headers: {{ 'Content-Type': 'application/json' }},
                  body: JSON.stringify(payload)
                }});
                const data = await response.json();
                const elapsed = Math.round(performance.now() - startedAt);

                document.getElementById('llmProvider').textContent = data.provider || '-';
                document.getElementById('llmModel').textContent = data.model || '-';
                document.getElementById('llmMode').textContent = `${{data.mode || 'unknown'}} · ${{elapsed}}ms`;
                result.textContent = data.output || JSON.stringify(data, null, 2);
                llmRaw.textContent = JSON.stringify(data, null, 2);
              }}

              async function refreshSupport() {{
                const response = await fetch('/v1/admin/support');
                const data = await response.json();
                document.getElementById('supportSnapshot').textContent = JSON.stringify(data, null, 2);
                document.getElementById('lastRefresh').textContent = `最近刷新 ${{new Date().toLocaleTimeString('zh-CN')}}`;
              }}

              window.addEventListener('load', () => {{
                refreshSupport();
              }});
            </script>
          </body>
        </html>
        """
        return HTMLResponse(html)

    return app


app = create_app()
