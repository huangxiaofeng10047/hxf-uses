---
description: springboot security 配置
slug: springboot-security
public: true
title: Spring Security 6 配置方法，废弃 WebSecurityConfigurerAdapter
createdAt: 1714910050896
updatedAt: 1714923038228
tags:
  - springboot
  - jdk17
heroImage: /cover.webp
---
在Spring Security 5.7.0-M2中，Spring就废弃了WebSecurityConfigurerAdapter，因为Spring官方鼓励用户转向基于组件的安全配置。本文整理了一下新的配置方法。 

配置的代码如下：
```code

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Autowired
    private JwtTokenProvider jwtTokenProvider;

    @Autowired
    private UserDetailsService userDetailsService;

    @Autowired
    private InvalidAuthenticationEntryPoint invalidAuthenticationEntryPoint;


    @Bean
    public PasswordEncoder passwordEncoder() {
        //return new BCryptPasswordEncoder();
        return PasswordEncoderFactories.createDelegatingPasswordEncoder();
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
                // 禁用basic明文验证
                .httpBasic().disable()
                // 前后端分离架构不需要csrf保护
                .csrf().disable()
                // 禁用默认登录页
                .formLogin().disable()
                // 禁用默认登出页
                .logout().disable()
                // 设置异常的EntryPoint，如果不设置，默认使用Http403ForbiddenEntryPoint
                .exceptionHandling(exceptions -> exceptions.authenticationEntryPoint(invalidAuthenticationEntryPoint))
                // 前后端分离是无状态的，不需要session了，直接禁用。
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(authorizeHttpRequests -> authorizeHttpRequests
                        // 允许所有OPTIONS请求
                        .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                        // 允许直接访问授权登录接口
                        .requestMatchers(HttpMethod.POST, "/authenticate").permitAll()
                        .requestMatchers(HttpMethod.POST, "/refresh_token").permitAll()
                        // 允许 SpringMVC 的默认错误地址匿名访问
                        .requestMatchers("/error").permitAll()
                        // 其他所有接口必须有Authority信息，Authority在登录成功后的UserDetailsImpl对象中默认设置“ROLE_USER”
                        //.requestMatchers("/**").hasAnyAuthority("ROLE_USER")
                        // 允许任意请求被已登录用户访问，不检查Authority
                        .anyRequest().authenticated())
                .authenticationProvider(authenticationProvider())
                // 加我们自定义的过滤器，替代UsernamePasswordAuthenticationFilter
                .addFilterBefore(authenticationJwtTokenFilter(), UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public UserDetailsService userDetailsService() {
        // 调用 JwtUserDetailService实例执行实际校验
        return username -> userDetailsService.loadUserByUsername(username);
    }

    /**
     * 调用loadUserByUsername获得UserDetail信息，在AbstractUserDetailsAuthenticationProvider里执行用户状态检查
     *
     * @return
     */
    @Bean
    public AuthenticationProvider authenticationProvider() {
        DaoAuthenticationProvider authProvider = new DaoAuthenticationProvider();
        // DaoAuthenticationProvider 从自定义的 userDetailsService.loadUserByUsername 方法获取UserDetails
        authProvider.setUserDetailsService(userDetailsService());
        // 设置密码编辑器
        authProvider.setPasswordEncoder(passwordEncoder());
        return authProvider;
    }

    /**
     * 登录时需要调用AuthenticationManager.authenticate执行一次校验
     *
     * @param config
     * @return
     * @throws Exception
     */
    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }

    @Bean
    public JwtTokenOncePerRequestFilter authenticationJwtTokenFilter() {
        return new JwtTokenOncePerRequestFilter();
    }
}



```
其中spring-security-config的6.1版本变化很多
![clipboard.png](/posts/springboot-security_clipboard-png.png)

如何改写了，现在建议使用lamada表达式的方式如下所示：
![clipboard2.png](/posts/springboot-security_clipboard2-png.png)

全都采用内聚的方式来写，采集官网的一段话如下所示：
```
Goals of the Lambda DSL
The Lambda DSL was created to accomplish to following goals:

Automatic indentation makes the configuration more readable.

There is no need to chain configuration options using .and()

The Spring Security DSL has a similar configuration style to other Spring DSLs such as Spring Integration and Spring Cloud Gateway.

Use .with() instead of .apply() for Custom DSLs
In versions prior to 6.2, if you had a custom DSL, you would apply it to the HttpSecurity using the HttpSecurity#apply(…​) method. However, starting from version 6.2, this method is deprecated and will be removed in 7.0 because it will no longer be possible to chain configurations using .and() once .and() is removed (see github.com/spring-projects/spring-security/issues/13067). Instead, it is recommended to use the new .with(…​) method. For more information about how to use .with(…​) please refer to the Custom DSLs section.

```
![clipboard3.png](/posts/springboot-security_clipboard3-png.png)
使用lambda方式成为spring的目标
4. Lambda DSL的目标
Lambda DSL 被开发出来，是为了完成以下的目的：

自动缩进以提高配置的可读性。
不再需要使用 .and() 方法来串联配置项。
Spring Security DSL 与其他 Spring DSLs (例如 Spring Integration 和 Spring Cloud Gateway ) 拥有相似的配置风格。
