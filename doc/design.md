design
======

J6uil#subscribe
      +-- lingr.room_show --> get: room/show
      +-- J6uil#buffer#switch
      +         +-- switch_buffer
      +         +-- update_message
      +
      +-- observe_start
            +-- lingr.subscribe --> get: room/subscribe all rooms
            +-- lingr.observe <-------+
                  +-- J6uil#_update --+
                      +-- J6uil#buffer#update
                          +-- cache
                          +   +-- cacheMgr.cache_message
                          +-- update
                              +-- message
                              +   +-- other room -- cacheMgr.count_up_unread
                              +   +-- same  room -- update_message (write to buf)
                              +
                              +-- presence
                                  +-- update_presence (write to buf)
                                      +-- cachemgr.cache_presence


