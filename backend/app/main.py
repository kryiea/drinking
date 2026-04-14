from typing import Optional

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse

from app.api.routes import admin, auth, drink_definitions, drink_logs, exports, goals, insights, profile, recommendations
from app.core.config import settings
from app.services.llm import OpenAICompatibleLLMService
from app.persistence.session import build_engine, init_database, make_session_factory, seed_database
from app.persistence.repository import SQLAlchemyRepository


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

        feedback_markup = "".join(
            (
                f"<li><strong>{item.category}</strong> · {item.status}"
                f"<br/>{item.content}</li>"
            )
            for item in feedback_items
        )
        rules_markup = "".join(
            f"<li>{rule}</li>" for rule in snapshot.rule_toggles.enabled_rules
        )

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
                --bg: #f3f7f4;
                --card: rgba(255,255,255,0.78);
                --ink: #18231f;
                --muted: #617169;
                --accent: #167c5e;
                --line: rgba(22, 124, 94, 0.12);
              }}
              * {{ box-sizing: border-box; }}
              body {{
                margin: 0;
                font-family: "SF Pro Display", "PingFang SC", sans-serif;
                background:
                  radial-gradient(circle at top left, rgba(22,124,94,0.10), transparent 30%),
                  linear-gradient(180deg, #f8fbf9 0%, var(--bg) 100%);
                color: var(--ink);
              }}
              main {{
                max-width: 1180px;
                margin: 0 auto;
                padding: 36px 20px 56px;
              }}
              .hero {{
                display: grid;
                gap: 16px;
                grid-template-columns: 1.35fr 1fr;
                margin-bottom: 20px;
              }}
              .card {{
                background: var(--card);
                backdrop-filter: blur(24px);
                border: 1px solid var(--line);
                border-radius: 28px;
                padding: 24px;
                box-shadow: 0 18px 50px rgba(16, 24, 20, 0.08);
              }}
              .eyebrow {{
                display: inline-flex;
                align-items: center;
                gap: 8px;
                font-size: 12px;
                letter-spacing: 0.08em;
                text-transform: uppercase;
                color: var(--accent);
                margin-bottom: 14px;
              }}
              h1, h2, h3, p {{ margin: 0; }}
              h1 {{ font-size: 34px; line-height: 1.06; margin-bottom: 10px; }}
              .subtle {{ color: var(--muted); line-height: 1.6; }}
              .grid {{
                display: grid;
                grid-template-columns: repeat(4, minmax(0, 1fr));
                gap: 16px;
                margin: 20px 0;
              }}
              .metric {{
                padding: 18px;
                border-radius: 22px;
                background: rgba(255,255,255,0.7);
                border: 1px solid rgba(255,255,255,0.88);
              }}
              .metric strong {{ display: block; font-size: 28px; margin-top: 8px; }}
              .stack {{
                display: grid;
                grid-template-columns: 1fr 1fr;
                gap: 16px;
                margin-top: 16px;
              }}
              ul {{
                margin: 14px 0 0;
                padding-left: 18px;
                color: var(--muted);
                line-height: 1.6;
              }}
              textarea {{
                width: 100%;
                min-height: 120px;
                border-radius: 18px;
                border: 1px solid var(--line);
                padding: 14px 16px;
                font: inherit;
                resize: vertical;
                background: rgba(255,255,255,0.9);
              }}
              button {{
                border: none;
                border-radius: 999px;
                padding: 12px 18px;
                background: var(--accent);
                color: white;
                font: inherit;
                font-weight: 600;
                cursor: pointer;
              }}
              .toolbar {{
                display: flex;
                align-items: center;
                justify-content: space-between;
                gap: 12px;
                margin-top: 18px;
              }}
              code {{
                font-family: "SF Mono", "Menlo", monospace;
                font-size: 12px;
                background: rgba(22,124,94,0.08);
                padding: 2px 6px;
                border-radius: 8px;
              }}
              .result {{
                white-space: pre-wrap;
                margin-top: 14px;
                padding: 14px 16px;
                border-radius: 18px;
                background: rgba(22,124,94,0.06);
                color: var(--ink);
                min-height: 72px;
              }}
              @media (max-width: 900px) {{
                .hero, .grid, .stack {{
                  grid-template-columns: 1fr;
                }}
              }}
            </style>
          </head>
          <body>
            <main>
              <section class="hero">
                <article class="card">
                  <div class="eyebrow">Yinzhi Support Console</div>
                  <h1>给开发者的 support 平台已经挂在本地后端上了。</h1>
                  <p class="subtle">
                    这里先覆盖规则开关、品牌库规模、反馈收口和 LLM 联调状态。
                    只要后端起来，这个页面就能作为本地开发和运营支持入口。
                  </p>
                  <div class="grid">
                    <div class="metric"><span>饮品条目</span><strong>{snapshot.drink_count}</strong></div>
                    <div class="metric"><span>品牌数量</span><strong>{snapshot.brand_count}</strong></div>
                    <div class="metric"><span>待处理反馈</span><strong>{snapshot.pending_feedback}</strong></div>
                    <div class="metric"><span>LLM 状态</span><strong>{"已配置" if llm_status.configured else "未配置"}</strong></div>
                  </div>
                  <p class="subtle">
                    API 基址: <code>{settings.support_base_url}</code> ·
                    JSON 快照: <code>/v1/admin/support</code> ·
                    健康检查: <code>/healthz</code>
                  </p>
                </article>
                <article class="card">
                  <div class="eyebrow">LLM Bridge</div>
                  <h2>OpenAI 兼容接口已经预留好。</h2>
                  <p class="subtle">
                    Provider: <code>{llm_status.provider}</code><br/>
                    Base URL: <code>{llm_status.base_url or "未配置"}</code><br/>
                    Model: <code>{llm_status.model or "未配置"}</code>
                  </p>
                  <div class="toolbar">
                    <span class="subtle">在这里可以直接试跑支持页的 LLM preview。</span>
                  </div>
                  <textarea id="llmPrompt">请为“首页字太多、需要更强层级”这条 UX 反馈给出 3 条开发建议。</textarea>
                  <div class="toolbar">
                    <button type="button" onclick="previewLLM()">运行 LLM Preview</button>
                    <span class="subtle" id="llmMode">当前模式: {"live" if llm_status.configured else "fallback"}</span>
                  </div>
                  <div class="result" id="llmResult">结果会显示在这里。</div>
                </article>
              </section>
              <section class="stack">
                <article class="card">
                  <div class="eyebrow">规则与服务</div>
                  <h3>当前规则开关</h3>
                  <ul>{rules_markup}</ul>
                  <ul>
                    <li>咖啡因预警阈值: {snapshot.rule_toggles.caffeine_warning_ratio:.0%}</li>
                    <li>糖分预警阈值: {snapshot.rule_toggles.sugar_warning_ratio:.0%}</li>
                    <li>晚间咖啡因截止: {snapshot.rule_toggles.late_caffeine_hour}:00</li>
                  </ul>
                </article>
                <article class="card">
                  <div class="eyebrow">反馈处理</div>
                  <h3>最近反馈</h3>
                  <ul>{feedback_markup}</ul>
                </article>
              </section>
            </main>
            <script>
              async function previewLLM() {{
                const prompt = document.getElementById('llmPrompt').value;
                const result = document.getElementById('llmResult');
                result.textContent = '请求中...';
                const response = await fetch('/v1/admin/llm-preview', {{
                  method: 'POST',
                  headers: {{ 'Content-Type': 'application/json' }},
                  body: JSON.stringify({{ prompt }})
                }});
                const data = await response.json();
                document.getElementById('llmMode').textContent = `当前模式: ${{data.mode}}`;
                result.textContent = data.output || JSON.stringify(data, null, 2);
              }}
            </script>
          </body>
        </html>
        """
        return HTMLResponse(html)

    return app


app = create_app()
